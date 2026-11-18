import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movies_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_ratings.dart';
import '../view_models/sign_up_view_model.dart';

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
                  MovieListViewModel(context.read<TmdbMovieService>())
                    ..loadInitial(),
              child: const MoviesScreen(),
            ),
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
          final extra = state.extra;
          return ChangeNotifierProvider(
            lazy: false,
            create: (context) => MovieDetailViewModel(
              context.read<TmdbMovieService>(),
              context.read<SessionRatings>(),
              movieId: movieId,
              initialMovie: extra is TmdbMovieDto ? extra : null,
            )..loadMovie(),
            child: const MovieDetailScreen(),
          );
        },
      ),
    ],
  );
}
