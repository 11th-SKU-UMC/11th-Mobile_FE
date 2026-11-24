import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/session_guard.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/movie_search_screen.dart';
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
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
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
            // 9주차: 5주차의 30개 수집 방식 대신 page 단위 "더 보기" ViewModel을 씁니다.
            builder: (context, state) =>
                ChangeNotifierProvider<PagedMoviesViewModel>(
                  create: (context) =>
                      PagedMoviesViewModel(
                          tmdbApi: context.read<TmdbMovieService>())
                        ..loadGenres()
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
                path: 'favorites', // 최종 경로: /my/favorites
                parentNavigatorKey: rootNavigatorKey, // 하단 NavigationBar를 가립니다.
                builder: (context, state) {
                  final auth = context.watch<AuthViewModel>();
                  final member = auth.member;
                  final guard = context.read<SessionGuard>();
                  if (member == null) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('내 즐겨찾기'),
                        centerTitle: true,
                      ),
                      body: Center(
                        child: auth.memberStatus == MemberLoadStatus.error
                            ? MovieLogButton(
                                label: '내 정보 다시 조회',
                                onPressed: () => auth.loadMember(force: true),
                              )
                            : const CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (guard.accountId != member.email) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ChangeNotifierProvider<FavoritesViewModel>(
                    // 계정이나 세션이 바뀌면 이전 사용자의 ViewModel을 버리고 새로 만듭니다.
                    key: ValueKey('${member.email}:${guard.generation}'),
                    create: (_) => FavoritesViewModel(
                      favoriteApi: context.read<FavoriteApiService>(),
                      tmdbApi: context.read<TmdbMovieService>(),
                      sessionGuard: guard,
                      accountId: member.email,
                    ),
                    child: FavoritesScreen(
                      onOpenMovie: (movie) async {
                        await context.push('/movies/${movie.id}', extra: movie);
                      },
                    ),
                  );
                },
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
      // 정적 경로 search는 동적 경로 :movieId보다 먼저 등록해야 합니다.
      // 순서가 바뀌면 "search"가 영화 ID로 해석됩니다.
      GoRoute(
        path: '/movies/search',
        builder: (context, state) => ChangeNotifierProvider<PagedMoviesViewModel>(
          // 영화 목록과는 별도의 인스턴스입니다.
          create: (context) =>
              PagedMoviesViewModel(tmdbApi: context.read<TmdbMovieService>()),
          child: MovieSearchScreen(
            onOpenMovie: (movie) async {
              await context.push('/movies/${movie.id}', extra: movie);
            },
          ),
        ),
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
          // 내 정보가 준비되고 현재 세션과 일치할 때까지 로딩을 보여 줍니다.
          final auth = context.watch<AuthViewModel>();
          final member = auth.member;
          final guard = context.read<SessionGuard>();
          if (member == null || guard.accountId != member.email) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: auth.memberStatus == MemberLoadStatus.error
                    ? MovieLogButton(
                        label: '내 정보 다시 조회',
                        onPressed: () => auth.loadMember(force: true),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }
          // movieId는 URL 식별자이고, 목록에서 넘긴 DTO는 state.extra로 받습니다.
          final extra = state.extra;
          return ChangeNotifierProvider<FavoriteDetailViewModel>(
            // 계정이나 세션이 바뀌면 새 ViewModel을 만듭니다.
            key: ValueKey('${member.email}:${guard.generation}'),
            create: (_) => FavoriteDetailViewModel(
              movieId: id,
              favoriteApi: context.read<FavoriteApiService>(),
              sessionGuard: guard,
              accountId: member.email,
            ),
            child: MovieDetailLoader(
              movieId: id,
              initialMovie:
                  extra is TmdbMovieDto && extra.id == id ? extra : null,
            ),
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
