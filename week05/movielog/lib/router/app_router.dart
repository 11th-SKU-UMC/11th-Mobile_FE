import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movies_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final currentIndex = switch (state.uri.path) {
            '/movies' => 1,
            '/my' => 2,
            _ => 0,
          };
          return MainScreen(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => ChangeNotifierProvider(
              lazy: false,
              create: (context) =>
                  MovieHomeViewModel(context.read<TmdbMovieService>())
                    ..loadPopular(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) => ChangeNotifierProvider(
              lazy: false,
              create: (context) =>
                  MovieListViewModel(context.read<TmdbMovieService>())
                    ..loadInitial(),
              child: const MoviesScreen(),
            ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
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
