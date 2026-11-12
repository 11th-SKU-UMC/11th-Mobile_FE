import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/genre_preference.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/learning_member_required_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  static final router = createRouter();

  /// 테스트에서도 독립된 Router를 만들 수 있도록 생성 함수를 분리합니다.
  static GoRouter createRouter({String initialLocation = '/start'}) {
    // ShellRoute 밖(root Navigator)에 화면을 띄울 때 사용하는 키입니다.
    final rootNavigatorKey = GlobalKey<NavigatorState>();

    return GoRouter(
      initialLocation: initialLocation,
      navigatorKey: rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => const StartScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const RegisterScreen(),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => ChangeNotifierProvider(
                create: (context) =>
                    MovieHomeViewModel(context.read<TmdbMovieService>())
                      ..loadPopular(),
                child: const HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/movies',
              builder: (context, state) => ChangeNotifierProvider(
                create: (context) => MovieListViewModel(
                  context.read<TmdbMovieService>(),
                  context.read<GenrePreference>(),
                )..loadInitial(),
                child: const MovieListScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':movieId', // 최종 경로: /movies/:movieId
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    // movieId는 URL 식별자로 쓰고, 목록에서 넘긴 DTO는 extra에서 꺼냅니다.
                    // 직접 접근·Deep Link에서는 extra가 없으므로 TMDB 상세로 다시 조회합니다.
                    final id = int.tryParse(
                      state.pathParameters['movieId'] ?? '',
                    );
                    final extra = state.extra;
                    return ChangeNotifierProvider(
                      create: (context) => MovieDetailViewModel(
                        context.read<TmdbMovieService>(),
                        context.read<RatingApiService>(),
                        context.read<LearningMemberSession>().memberId,
                        id,
                        initialMovie: extra is TmdbMovieDto && extra.id == id
                            ? extra
                            : null,
                      )..load(),
                      child: const MovieDetailScreen(),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/my',
              builder: (context, state) => const MyPageScreen(),
              routes: [
                GoRoute(
                  path: 'ratings', // 최종 경로: /my/ratings
                  // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    // 6주차 고정 memberId 1 대신 회원가입 결과로 받은 학습용 ID를 사용합니다.
                    final id = context.read<LearningMemberSession>().memberId;
                    if (id == null) {
                      return const LearningMemberRequiredScreen(
                        title: '내가 등록한 평점',
                      );
                    }
                    return ChangeNotifierProvider(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        id,
                      )..load(),
                      child: const MyRatingsScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
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
