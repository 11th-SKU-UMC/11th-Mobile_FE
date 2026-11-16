import 'package:flutter/material.dart';

// import 'package:movielog/screens/profile_screen.dart';
// import 'screens/start_screen.dart';
// import 'screens/signup_screen.dart';
// import 'screens/rating_screen.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

import 'package:provider/provider.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 자체 백엔드 Client는 두 Service가 하나를 공유합니다. (TMDB Client와 합치지 않음)
    final movieLogClient = createMovieLogClient();

    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<MemberCheckService>(
          create: (_) => MemberCheckService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(movieLogClient),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

//  home: const RatingScreen(
//         movieTitle: 'Hero Under the Starlight',
//         posterAssetPath: 'assets/images/posters/hero_under_the_starlight.jpg',
//       ),
