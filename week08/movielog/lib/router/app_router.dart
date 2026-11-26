import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/genre_preference.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

/// 인증 상태만 보고 이동할 경로를 정합니다. API 호출 같은 비동기 작업은 하지 않습니다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면을 유지합니다.
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용합니다.
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냅니다.
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  /// Router는 앱이 살아있는 동안 한 번만 만듭니다(`_MovieLogRouterApp.initState`).
  static GoRouter createRouter(AuthViewModel authViewModel) {
    // ShellRoute 밖(root Navigator)에 화면을 띄울 때 사용하는 키입니다.
    final rootNavigatorKey = GlobalKey<NavigatorState>();

    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      // redirect는 이동할 때만 호출되므로, 인증 상태가 바뀌면 다시 검사하도록 연결합니다.
      refreshListenable: authViewModel,
      redirect: (context, state) =>
          authRedirect(authViewModel.status, state.uri.path),
      routes: [
        GoRoute(
          path: '/start', // 스플래시: 토큰 확인 중 / 확인 실패 시 재시도
          builder: (context, state) => const SplashRoute(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final extra = state.extra;
            return LoginScreen(initialEmail: extra is String ? extra : null);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const RegisterScreen(),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => ChangeNotifierProvider(
                create: (context) =>
                    MovieHomeViewModel(context.read<TmdbMovieService>())
                      ..loadPopular(),
                child: const HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/movies',
              builder: (context, state) => ChangeNotifierProvider(
                create: (context) => MovieListViewModel(
                  context.read<TmdbMovieService>(),
                  context.read<GenrePreference>(),
                )..loadInitial(),
                child: const MovieListScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':movieId', // 최종 경로: /movies/:movieId
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    // movieId는 URL 식별자로 쓰고, 목록에서 넘긴 DTO는 extra에서 꺼냅니다.
                    // 직접 접근·Deep Link에서는 extra가 없으므로 TMDB 상세로 다시 조회합니다.
                    final id = int.tryParse(
                      state.pathParameters['movieId'] ?? '',
                    );
                    final extra = state.extra;
                    return ChangeNotifierProvider(
                      create: (context) => MovieDetailViewModel(
                        context.read<TmdbMovieService>(),
                        context.read<RatingApiService>(),
                        context.read<AuthViewModel>(),
                        context.read<MyRatingsViewModel>(),
                        id,
                        initialMovie: extra is TmdbMovieDto && extra.id == id
                            ? extra
                            : null,
                      )..load(),
                      child: const MovieDetailScreen(),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/my',
              builder: (context, state) => const MyPageScreen(),
              routes: [
                GoRoute(
                  path: 'ratings', // 최종 경로: /my/ratings
                  // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                  // 7주차의 memberId 대신 토큰 기반 세션 목록(MyRatingsViewModel)을 사용합니다.
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const MyRatingsScreen(),
                ),
                GoRoute(
                  path: 'profile/edit', // 최종 경로: /my/profile/edit
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const _EditProfileRoute(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;
    return 0;
  }
}

/// 내 정보가 아직 없으면 로딩·재시도를 보여주고, 있으면 수정 화면을 엽니다.
class _EditProfileRoute extends StatelessWidget {
  const _EditProfileRoute();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.member == null) {
      return Scaffold(
        appBar: AppBar(centerTitle: true, title: const Text('프로필 수정')),
        body: Center(
          child: auth.memberStatus == MemberLoadStatus.error
              ? MovieLogButton(
                  label: '다시 시도',
                  onPressed: () => auth.loadMember(force: true),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    return ChangeNotifierProvider<EditProfileViewModel>(
      create: (context) => EditProfileViewModel(
        context.read<MemberApiService>(),
        context.read<AuthViewModel>(),
      ),
      child: const EditProfileScreen(),
    );
  }
}
