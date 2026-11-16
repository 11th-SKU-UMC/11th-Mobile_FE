import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'view_models/movie_home_view_model.dart';
import 'view_models/movie_list_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final movieService = TmdbMovieService(createTmdbClient());

  runApp(MovieLogApp(movieService: movieService));
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key, required this.movieService});

  final TmdbMovieService movieService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>.value(value: movieService),
        ChangeNotifierProvider(
          create: (_) => MovieHomeViewModel(movieService)..loadPopular(),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieListViewModel(movieService)..initialize(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: ThemeData(useMaterial3: true),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
