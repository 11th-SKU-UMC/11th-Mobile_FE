import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/start_screen.dart';
import 'package:movielog/SignUpScreen/sign_up_screen.dart';
import 'package:movielog/home_screen.dart';
import 'package:movielog/movie_list_screen.dart';
import 'package:movielog/movie_detail_screen.dart';
import 'package:movielog/my_page_screen.dart';
import 'package:movielog/main_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';

class AppRouter {
  AppRouter._();

  // root Navigator를 가리키는 키를 클래스에서 한 번만 선언합니다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey, // GoRouter 전체가 사용할 root Navigator
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) =>
              SignUpViewModel(context.read<MemberCheckService>()),
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
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) => MovieDetailScreen(
                      movieId: state.pathParameters['movieId']!,
                      movie: state.extra as TmdbMovieDto?,
                    ),
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
                    path: 'ratings', // 최종 경로: /my/ratings
                    // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<TmdbMovieService>(),
                            sampleMemberId, // 6주차는 학습용 ID 1
                          )..load(),
                          child: const MyRatingsScreen(),
                        ),
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
