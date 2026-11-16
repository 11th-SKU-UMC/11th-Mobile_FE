import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/genre_preference.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/learning_member_session.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.router,
    this.tmdbMovieService,
    this.signUpService,
    this.ratingApiService,
    this.genrePreference,
    this.learningMemberSession,
  });

  /// 아래 값들은 테스트에서 대체 구현을 주입할 때만 사용합니다.
  final GoRouter? router;
  final TmdbMovieService? tmdbMovieService;
  final SignUpService? signUpService;
  final RatingApiService? ratingApiService;
  final GenrePreference? genrePreference;
  final LearningMemberSession? learningMemberSession;

  @override
  Widget build(BuildContext context) {
    // 회원·평점 Service는 같은 워크북 백엔드를 호출하므로 Dio 하나를 공유합니다.
    // TMDB Client와는 분리해 TMDB Token이 MovieLog API로 가지 않게 합니다.
    final movieLogClient = createMovieLogClient();

    return MultiProvider(
      providers: [
        // 회원가입 결과의 memberId를 영화 상세·마이페이지 Route가 함께 읽습니다.
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => learningMemberSession ?? LearningMemberSession(),
        ),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
        ),
        Provider<SignUpService>(
          create: (_) => signUpService ?? SignUpService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => ratingApiService ?? RatingApiService(movieLogClient),
        ),
        Provider<GenrePreference>(
          create: (_) => genrePreference ?? GenrePreference(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: router ?? AppRouter.router,
      ),
    );
  }
}
