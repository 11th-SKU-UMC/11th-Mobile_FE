import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/sign_up_service.dart';
import '../view_models/learning_member_session.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movies_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
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
            routes: [
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final memberId = context
                      .read<LearningMemberSession>()
                      .memberId;
                  if (memberId == null) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('내가 등록한 평점'),
                        centerTitle: true,
                      ),
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('학습용 회원가입이 필요합니다.'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.push('/signup'),
                              child: const Text('회원가입'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ChangeNotifierProvider(
                    create: (context) => MyRatingsViewModel(
                      context.read<RatingApiService>(),
                      context.read<TmdbMovieService>(),
                      memberId,
                    )..load(),
                    child: const MyRatingsScreen(),
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
          final extra = state.extra;
          return ChangeNotifierProvider(
            lazy: false,
            create: (context) => MovieDetailViewModel(
              context.read<TmdbMovieService>(),
              movieId: movieId,
              initialMovie: extra is TmdbMovieDto ? extra : null,
              memberId: context.read<LearningMemberSession>().memberId,
              ratingService: context.read<RatingApiService>(),
            )..loadMovie(),
            child: const MovieDetailScreen(),
          );
        },
      ),
    ],
  );
}
