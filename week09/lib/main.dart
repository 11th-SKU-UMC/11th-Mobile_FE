import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'data/services/sign_up_service.dart';
import 'view_models/learning_member_session.dart';
import 'data/services/tmdb_movie_service.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/member_api_service.dart';
import 'router/app_router.dart';
import 'view_models/signup_view_model.dart';

import 'data/services/rating_api_service.dart';
import 'data/services/favorite_api_service.dart';

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

  final publicMovieLogClient =
    createPublicMovieLogClient();

  final authMovieLogClient =
      createAuthMovieLogClient();

  final signUpService =
      SignUpService(publicMovieLogClient);

  final authApiService =
      AuthApiService(publicMovieLogClient);

  final ratingApiService =
      RatingApiService(authMovieLogClient);

  final memberApiService =
    MemberApiService(authMovieLogClient);

  final favoriteApiService =
    FavoriteApiService(authMovieLogClient);

  runApp(
    MovieLogApp(
      tmdbMovieService: tmdbMovieService,
      signUpService: signUpService,
      ratingApiService: ratingApiService,
      authApiService: authApiService,
      memberApiService: memberApiService,
      favoriteApiService: favoriteApiService,
    ),
  );
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    required this.tmdbMovieService,
    required this.signUpService,
    required this.ratingApiService,
    required this.authApiService,
    required this.memberApiService,
    required this.favoriteApiService,
  });

  final TmdbMovieService tmdbMovieService;
  final SignUpService signUpService;
  final RatingApiService ratingApiService;
  final AuthApiService authApiService;
  final MemberApiService memberApiService;
  final FavoriteApiService favoriteApiService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>.value(
          value: tmdbMovieService,
        ),

        Provider<SignUpService>.value(
          value: signUpService,
        ),

        Provider<RatingApiService>.value(
          value: ratingApiService,
        ),

        Provider<AuthApiService>.value(
          value: authApiService,
        ),

        Provider<MemberApiService>.value(
          value: memberApiService,
        ),

        Provider<FavoriteApiService>.value(
          value: favoriteApiService,
        ),

        ChangeNotifierProvider(
          create: (_) => MovieHomeViewModel(
            tmdbMovieService,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => MovieListViewModel(
            tmdbMovieService,
          )..initialize(),
        ),

        ChangeNotifierProvider(
          create: (_) => SignupViewModel(
            signUpService,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => LearningMemberSession(),
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