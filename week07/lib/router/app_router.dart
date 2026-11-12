import 'package:go_router/go_router.dart';

import '../screens/start_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';

import '../data/models/tmdb_movie_dto.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';

import '../data/services/rating_api_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';

import '../data/services/tmdb_movie_service.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MovieListScreen(),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(
            state.pathParameters['movieId'] ?? '',
          );

          final movie = state.extra is TmdbMovieDto
              ? state.extra as TmdbMovieDto
              : null;

          if (movieId == null || movieId < 1) {
            return const Scaffold(
              body: Center(
                child: Text('영화 ID가 올바르지 않습니다.'),
              ),
            );
          }

          if (movie == null) {
            return const Scaffold(
              body: Center(
                child: Text('영화 정보를 불러오지 못했습니다.'),
              ),
            );
          }

          return ChangeNotifierProvider(
            create: (context) => MovieDetailViewModel(
              context.read<RatingApiService>(),
              context.read<LearningMemberSession>().memberId,
              movie,
            ),
            child: MovieDetailScreen(
              movieId: movieId,
              movie: movie,
            ),
          );
        },
      ),
      GoRoute(
        path: '/my',
        builder: (context, state) =>
            const MyPageScreen(),
      ),

      GoRoute(
        path: '/my/ratings',
        builder: (context, state) {
          final memberId =
              context.read<LearningMemberSession>().memberId;

          if (memberId == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('내가 등록한 평점'),
              ),
              body: const Center(
                child: Text(
                  '학습용 회원가입이 필요합니다.',
                ),
              ),
            );
          }

          return ChangeNotifierProvider(
            create: (context) =>
                MyRatingsViewModel(
              ratingApiService:
                  context.read<RatingApiService>(),
              tmdbMovieService:
                  context.read<TmdbMovieService>(),
              memberId: memberId,
            )..loadRatings(),
            child: const MyRatingsScreen(),
          );
        },
      ),
    ],
  );
}
