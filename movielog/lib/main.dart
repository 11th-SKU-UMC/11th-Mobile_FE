import 'package:provider/provider.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

import 'package:flutter/material.dart';
import 'package:movielog/ProfileScreens/ProfileBody/profile_screen.dart';
import 'package:movielog/theme/app_colors.dart';

import 'theme/app_theme.dart';

import 'package:movielog/start_screen.dart';

import 'package:movielog/SignUpScreen/sign_up_screen.dart';

import 'package:movielog/router/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

// void main() => runApp(const MovieLogApp());

/* class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    title: 'MovieLog',
    home: const StartScreen(),
    // home: const ProfileScreen(),
    // home: const SignUpScreen(),
  );
} */

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) {
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
        theme: AppTheme.light,
        title: 'MovieLog',
        // home: const StartScreen(),
        // home: const ProfileScreen(),
        // home: const SignUpScreen(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
