import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

/// 앱에서 쓰는 경로 모음. 문자열을 화면마다 직접 쓰지 않도록 한곳에 둔다.
abstract final class AppRoutes {
  static const String start = '/start';
  static const String register = '/register';
  static const String home = '/home';
  static const String movies = '/movies';
  static const String my = '/my';

  /// 마이페이지의 자식 화면 '내가 등록한 평점'.
  static const String myRatings = '$my/ratings';

  /// 상세 화면 경로. [movieId]는 TMDB 영화 id. 예: `/movies/550`
  static String movieDetail(int movieId) => '$movies/$movieId';
}

class AppRouter {
  AppRouter._();

  /// 앱 전체의 root Navigator. 탭 바 없이 전체 화면으로 띄울 Route의
  /// parentNavigatorKey로 지정한다.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.start,
    routes: [
      GoRoute(
        path: AppRoutes.start,
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        // 중복 확인 상태는 회원가입 화면에서만 쓰므로 Route에서 ViewModel을 만든다.
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) =>
              SignUpViewModel(context.read<MemberCheckService>()),
          child: const SignUpScreen(),
        ),
      ),
      // 상세 화면은 탭 바 없이 전체 화면으로 보여야 하므로 Shell 바깥(root Navigator)에 둔다.
      // `/movies`보다 먼저 선언해야 `/movies/1`이 이 Route와 매칭된다.
      // 목록·홈에서 넘긴 TmdbMovieDto는 extra로 받는다. (URL에는 TMDB id만 남는다)
      GoRoute(
        path: '${AppRoutes.movies}/:movieId',
        builder: (context, state) => MovieDetailScreen(
          movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
          movie: state.extra is TmdbMovieDto
              ? state.extra! as TmdbMovieDto
              : null,
        ),
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
                    builder: (context, state) =>
                        ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<TmdbMovieService>(),
                            sampleMemberId, // 6주차는 학습용 memberId 1
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
