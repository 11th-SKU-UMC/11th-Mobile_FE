import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) {
          return const StartScreen();
        },
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) {
          return const RegisterScreen();
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          final path = state.uri.path;

          int currentIndex = 0;

          if (path.startsWith('/movies')) {
            currentIndex = 1;
          } else if (path.startsWith('/my')) {
            currentIndex = 2;
          }

          return MainScreen(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) {
              return const HomeScreen();
            },
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) {
              return const MovieListScreen();
            },
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) {
              return const MyPageScreen();
            },
          ),
        ],
      ),

      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');

          final movie = findMovieById(movieId);

          return MovieDetailScreen(movie: movie);
        },
      ),
    ],
  );
}
