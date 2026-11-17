import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/rating_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/start_screen.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/session_ratings_store.dart';
import '../data/services/member_api_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/login_screen.dart';
import '../widgets/movielog_button.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  // root Navigator를 가리키는 키를 한 번만 선언합니다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  /// 인증 상태에 따른 화면 이동 규칙입니다. 상태만 읽고, 비동기 작업은 하지 않습니다.
  static String? authRedirect(AuthStatus status, String location) {
    const publicPaths = {'/login', '/signup'};
    final atStart = location == '/start';
    final atPublic = publicPaths.contains(location);

    return switch (status) {
      // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
      AuthStatus.initializing ||
      AuthStatus.retryRequired => atStart ? null : '/start',
      // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
      AuthStatus.signedOut ||
      AuthStatus.authenticating => atPublic ? null : '/login',
      // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냄
      AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
    };
  }

  // GoRouter는 앱이 살아있는 동안 한 번만 만들어야 합니다.
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey, // GoRouter 전체가 사용할 root Navigator
    refreshListenable: authViewModel, // 인증 상태가 바뀌면 redirect를 다시 실행합니다.
    redirect: (context, state) =>
        authRedirect(authViewModel.status, state.uri.path),
    routes: [
      GoRoute(
        path: '/start', // 스플래시: 토큰 확인 중 / 확인 실패 시 재시도
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          return SplashScreen(
            message: auth.message,
            onRetry: auth.status == AuthStatus.retryRequired
                ? auth.restoreSession
                : null,
          );
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/rating',
        builder: (context, state) => const RatingScreen(
          movieTitle: 'Hero Under the Starlight',
          posterAssetPath: 'assets/images/posters/hero_under_the_starlight.jpg',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(), // 기존 홈 화면 위젯 이름 그대로
                ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MovieListScreen(),
                ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'ratings', // 최종 경로: /my/ratings
                // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    ChangeNotifierProvider<MyRatingsViewModel>(
                  create: (context) => MyRatingsViewModel(
                    context.read<RatingApiService>(),
                    context.read<TmdbMovieService>(),
                    context.read<AuthViewModel>(),
                    context.read<SessionRatingsStore>(),
                  )..load(),
                  child: const MyRatingsScreen(),
                ),
              ),
              GoRoute(
                path: 'profile/edit', // 최종 경로: /my/profile/edit
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
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
                      auth,
                    ),
                    child: const EditProfileScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('영화 ID가 올바르지 않습니다.')),
            );
          }
          // movieId는 URL 식별자이고, 목록에서 넘긴 DTO는 state.extra로 받습니다.
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id ? extra : null,
          );
        },
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
