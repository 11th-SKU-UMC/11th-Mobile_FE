import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'data/services/member_check_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'view_models/signup_view_model.dart';

import 'data/services/rating_api_service.dart';
import 'view_models/my_ratings_view_model.dart';

import 'view_models/movie_home_view_model.dart';
import 'view_models/movie_list_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );

  final tmdbClient = createTmdbClient();
  final tmdbMovieService =
      TmdbMovieService(tmdbClient);

  final movieLogClient =
      createMovieLogClient();

  final memberCheckService =
      MemberCheckService(movieLogClient);

  final ratingApiService =
    RatingApiService(movieLogClient);

  runApp(
    MovieLogApp(
      tmdbMovieService: tmdbMovieService,
      memberCheckService: memberCheckService,
      ratingApiService: ratingApiService,
    ),
  );
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    required this.tmdbMovieService,
    required this.memberCheckService,
    required this.ratingApiService,
  });

  final TmdbMovieService tmdbMovieService;
  final MemberCheckService memberCheckService;
  final RatingApiService ratingApiService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>.value(
          value: tmdbMovieService,
        ),

        Provider<MemberCheckService>.value(
          value: memberCheckService,
        ),

        Provider<RatingApiService>.value(
          value: ratingApiService,
        ),

        ChangeNotifierProvider(
          create: (_) => MovieHomeViewModel(
            tmdbMovieService,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => MovieListViewModel(
            tmdbMovieService,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => SignupViewModel(
            memberCheckService,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => MyRatingsViewModel(
            ratingApiService: ratingApiService,
            tmdbMovieService: tmdbMovieService,
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: ThemeData(
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}