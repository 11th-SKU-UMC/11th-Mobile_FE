import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';

/// 앱에서 쓰는 경로 모음. 문자열을 화면마다 직접 쓰지 않도록 한곳에 둔다.
abstract final class AppRoutes {
  static const String start = '/start';
  static const String register = '/register';
  static const String home = '/home';
  static const String movies = '/movies';
  static const String my = '/my';

  /// 상세 화면 경로. 예: `/movies/1`
  static String movieDetail(int movieId) => '$movies/$movieId';

  /// 장르 필터를 Query Parameter로 담은 목록 경로.
  /// 예: `/movies?genre=드라마&genre=SF`. 장르가 없으면 `/movies`.
  static String moviesWithGenres(Iterable<String> genres) {
    final list = genres.toList();
    if (list.isEmpty) return movies;
    return Uri(path: movies, queryParameters: {'genre': list}).toString();
  }
}

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.start,
    routes: [
      GoRoute(
        path: AppRoutes.start,
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const SignUpScreen(),
      ),
      // 상세 화면은 탭 바 없이 전체 화면으로 보여야 하므로 Shell 바깥(root Navigator)에 둔다.
      // `/movies`보다 먼저 선언해야 `/movies/1`이 이 Route와 매칭된다.
      GoRoute(
        path: '${AppRoutes.movies}/:movieId',
        builder: (context, state) => MovieDetailScreen(
          movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.movies,
                builder: (context, state) => MovieListScreen(
                  selectedGenres:
                      state.uri.queryParametersAll['genre'] ?? const [],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.my,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
