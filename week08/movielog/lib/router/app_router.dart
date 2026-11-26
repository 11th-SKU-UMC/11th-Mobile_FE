import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/splash_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_ratings_store.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

/// 앱에서 쓰는 경로 모음. 문자열을 화면마다 직접 쓰지 않도록 한곳에 둔다.
abstract final class AppRoutes {
  static const String start = '/start';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String movies = '/movies';
  static const String my = '/my';

  /// 마이페이지의 자식 화면 '내가 등록한 평점'.
  static const String myRatings = '$my/ratings';

  /// 마이페이지의 자식 화면 '프로필 수정'.
  static const String profileEdit = '$my/profile/edit';

  /// 로그인하지 않아도 볼 수 있는 화면.
  static const Set<String> publicPaths = {login, register};

  /// 상세 화면 경로. [movieId]는 TMDB 영화 id. 예: `/movies/550`
  static String movieDetail(int movieId) => '$movies/$movieId';
}

/// 인증 상태에 따라 보낼 경로. 그대로 둘 때는 null.
///
/// 상태만 읽고 판단한다. API 호출 같은 비동기 작업은 하지 않는다.
String? authRedirect(AuthStatus status, String location) {
  final atStart = location == AppRoutes.start;
  final atPublic = AppRoutes.publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : AppRoutes.start,
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : AppRoutes.login,
    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? AppRoutes.home : null,
  };
}

class AppRouter {
  AppRouter._();

  /// 앱 전체의 root Navigator. 탭 바 없이 전체 화면으로 띄울 Route의
  /// parentNavigatorKey로 지정한다.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// [authViewModel]이 바뀔 때마다 redirect를 다시 실행한다.
  /// 앱이 살아있는 동안 한 번만 만든다. (build에서 만들면 위치가 초기화된다)
  static GoRouter createRouter(AuthViewModel authViewModel) => GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.start,
    refreshListenable: authViewModel,
    redirect: (context, state) =>
        authRedirect(authViewModel.status, state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.start, // 스플래시: 토큰 확인 중 / 확인 실패 시 재시도
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
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        // 중복 확인 상태는 회원가입 화면에서만 쓰므로 Route에서 ViewModel을 만든다.
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),
      // 상세 화면은 탭 바 없이 전체 화면으로 보여야 하므로 Shell 바깥(root Navigator)에 둔다.
      // `/movies`보다 먼저 선언해야 `/movies/1`이 이 Route와 매칭된다.
      // 목록·홈에서 넘긴 TmdbMovieDto는 extra로 받는다. (URL에는 TMDB id만 남는다)
      // 직접 접근·Deep Link처럼 extra가 없으면 Loader가 TMDB 상세 API로 다시 조회한다.
      GoRoute(
        path: '${AppRoutes.movies}/:movieId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) return const InvalidMovieIdScreen();
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          );
        },
      ),
      // 탭마다 독립된 Navigator와 상태(스크롤 위치 등)를 유지한다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                // 화면별 ViewModel은 Route에서 만든다. create는 한 번만 실행되므로
                // Popular 요청이 build마다 반복되지 않고, Route가 사라지면 dispose된다.
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieHomeViewModel>(
                      create: (context) =>
                          MovieHomeViewModel(context.read<TmdbMovieService>())
                            ..loadPopular(),
                      child: const HomeScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.movies,
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieListViewModel>(
                      create: (context) =>
                          MovieListViewModel(context.read<TmdbMovieService>())
                            ..loadInitial(),
                      child: const MovieListScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.my,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings', // 최종 경로: /my/ratings
                    // 지정하지 않으면 마이 탭 Branch의 Navigator에 쌓여 하단 탭이 남는다.
                    // root Navigator 위에 띄워 하단 NavigationBar를 가린다.
                    parentNavigatorKey: rootNavigatorKey,
                    // 7주차 memberId 대신 토큰 기반 Service와 현재 세션 평점 목록을 쓴다.
                    builder: (context, state) =>
                        ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<AuthViewModel>(),
                            context.read<SessionRatingsStore>(),
                          ),
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
                          appBar: const CommonAppBar(
                            title: '프로필 수정',
                            centerTitle: true,
                          ),
                          body: Center(
                            child: auth.memberStatus == MemberLoadStatus.error
                                ? MovieLogButton(
                                    label: '다시 시도',
                                    onPressed: () =>
                                        auth.loadMember(force: true),
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
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
