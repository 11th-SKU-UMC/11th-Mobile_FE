import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/session_guard.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/movie_record_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_search_screen.dart';
import '../screens/movies_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../view_models/session_ratings.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

String? authRedirect(AuthStatus status, String path) {
  const publicPaths = {'/login', '/register', '/signup'};
  final atPublic = publicPaths.contains(path);
  return switch (status) {
    AuthStatus.initializing ||
    AuthStatus.retryRequired => path == '/start' ? null : '/start',
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    AuthStatus.signedIn =>
      path == '/start' || path == '/' || atPublic ? '/home' : null,
  };
}

class AppRouter {
  AppRouter(this._auth);

  final AuthViewModel _auth;
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  late final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: _auth,
    redirect: (_, state) => authRedirect(_auth.status, state.uri.path),
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', redirect: (_, _) => '/register'),
      GoRoute(
        path: '/register',
        builder: (context, _) => ChangeNotifierProvider(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),
      ShellRoute(
        builder: (_, state, child) {
          final path = state.uri.path;
          final currentIndex = path.startsWith('/movies')
              ? 1
              : path.startsWith('/my')
              ? 2
              : 0;
          return MainScreen(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => ChangeNotifierProvider(
              lazy: false,
              create: (context) =>
                  MovieHomeViewModel(context.read<TmdbMovieService>())
                    ..loadPopular(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (_, _) => ChangeNotifierProvider(
              lazy: false,
              create: (context) =>
                  PagedMoviesViewModel(context.read<TmdbMovieService>())
                    ..loadGenres()
                    ..loadInitial(),
              child: const MoviesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'search',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, _) => ChangeNotifierProvider(
                  create: (context) => PagedMoviesViewModel(
                    context.read<TmdbMovieService>(),
                    searchMode: true,
                  ),
                  child: const MovieSearchScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/my',
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'profile/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, _) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, _) => ChangeNotifierProvider(
                  create: (context) =>
                      MyRatingsViewModel(context.read<SessionRatings>()),
                  child: const MyRatingsScreen(),
                ),
              ),
              GoRoute(
                path: 'favorites',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, _) {
                  final auth = context.watch<AuthViewModel>();
                  final guard = context.read<SessionGuard>();
                  final email = auth.member?.email;
                  if (email == null ||
                      !guard.isCurrent(guard.generation, email)) {
                    return const _VerifyMemberScreen(
                      title: '내 즐겨찾기',
                      backPath: '/my',
                    );
                  }
                  return ChangeNotifierProvider(
                    key: ValueKey((email, guard.generation)),
                    create: (context) => FavoritesViewModel(
                      context.read<FavoriteApiService>(),
                      context.read<TmdbMovieService>(),
                      guard,
                      email,
                    )..refresh(),
                    child: const FavoritesScreen(),
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
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (movieId == null || movieId <= 0) {
            return const Scaffold(
              body: Center(child: Text('올바른 영화 ID가 아닙니다.')),
            );
          }
          final auth = context.watch<AuthViewModel>();
          final guard = context.read<SessionGuard>();
          final email = auth.member?.email;
          if (email == null || !guard.isCurrent(guard.generation, email)) {
            return const _VerifyMemberScreen(
              title: 'MovieLog',
              backPath: '/movies',
            );
          }
          final extra = state.extra;
          return MultiProvider(
            key: ValueKey((email, guard.generation, movieId)),
            providers: [
              ChangeNotifierProvider(
                create: (context) => FavoriteDetailViewModel(
                  context.read<FavoriteApiService>(),
                  guard,
                  email,
                  movieId,
                )..refresh(),
              ),
              ChangeNotifierProvider(
                create: (context) => MovieDetailViewModel(
                  context.read<TmdbMovieService>(),
                  context.read<SessionRatings>(),
                  favorite: context.read<FavoriteDetailViewModel>(),
                  records: context.read<MovieRecordApiService>(),
                  movieId: movieId,
                  initialMovie: extra is TmdbMovieDto ? extra : null,
                )..loadMovie(),
              ),
            ],
            child: const MovieDetailScreen(),
          );
        },
      ),
    ],
  );
}

class _VerifyMemberScreen extends StatefulWidget {
  const _VerifyMemberScreen({required this.title, required this.backPath});

  final String title;
  final String backPath;

  @override
  State<_VerifyMemberScreen> createState() => _VerifyMemberScreenState();
}

class _VerifyMemberScreenState extends State<_VerifyMemberScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      if (auth.memberStatus == MemberLoadStatus.idle) auth.loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.title,
        centerTitle: true,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(widget.backPath),
      ),
      body: auth.memberStatus == MemberLoadStatus.error
          ? MovieListError(message: auth.memberError!, onRetry: auth.loadMember)
          : const MovieListLoading(),
    );
  }
}
