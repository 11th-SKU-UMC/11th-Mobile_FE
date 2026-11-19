import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/start_screen.dart';
import 'package:movielog/SignUpScreen/sign_up_screen.dart';
import 'package:movielog/home_screen.dart';
import 'package:movielog/movie_list_screen.dart';
import 'package:movielog/my_page_screen.dart';
import 'package:movielog/main_screen.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/movielog_button.dart';

// redirect 안에서는 상태만 읽고 판단합니다. API 호출 같은 비동기 작업은 하지 않습니다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
    AuthStatus.initializing || AuthStatus.retryRequired =>
      atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut || AuthStatus.authenticating =>
      atPublic ? null : '/login',
    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // 8주차: AuthViewModel을 refreshListenable로 연결하려고 인스턴스를 받습니다.
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authViewModel, // 인증 상태가 바뀌면 redirect를 다시 실행
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
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const SignUpScreen(),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            // 홈 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
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
            // 영화 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  builder: (context, state) =>
                      ChangeNotifierProvider<MovieListViewModel>(
                        create: (context) =>
                            MovieListViewModel(context.read<TmdbMovieService>())
                              ..loadInitial(),
                        child: const MovieListScreen(),
                      ),
                  routes: [
                    // 7주차: movieId는 URL 식별자, 영화 DTO는 extra 또는 TMDB 재조회
                    GoRoute(
                      path: ':movieId',
                      builder: (context, state) {
                        final id = int.tryParse(
                          state.pathParameters['movieId'] ?? '',
                        );
                        if (id == null || id < 1) {
                          return const Scaffold(
                            body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
                          );
                        }
                        final extra = state.extra;
                        return MovieDetailLoader(
                          movieId: id,
                          initialMovie: extra is TmdbMovieDto && extra.id == id
                              ? extra
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // 마이 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const MyPageScreen(),
                  routes: [
                    GoRoute(
                      path: 'ratings', // /my/ratings
                      parentNavigatorKey: rootNavigatorKey,
                      // 8주차: memberId 대신 현재 세션에서 등록한 Rating을 토큰 기반으로 수정·삭제
                      builder: (context, state) =>
                          ChangeNotifierProvider<MyRatingsViewModel>(
                            create: (context) => MyRatingsViewModel(
                              context.read<RatingApiService>(),
                              context.read<TmdbMovieService>(),
                              context.read<SessionRatingsStore>(),
                              context.read<AuthViewModel>(),
                            )..load(),
                            child: const MyRatingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'profile/edit', // /my/profile/edit
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();
                        if (auth.member == null) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('프로필 수정')),
                            body: Center(
                              child:
                                  auth.memberStatus == MemberLoadStatus.error
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
          ],
        ),
      ],
    );
  }
}
