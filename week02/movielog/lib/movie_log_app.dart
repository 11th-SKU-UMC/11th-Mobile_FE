import 'package:flutter/material.dart';
import 'package:movielog/screens/profile_screen.dart';

import 'screens/start_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/rating_screen.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      home: const SignUpScreen(),
    );
  }
}


//  home: const RatingScreen(
//         movieTitle: 'Hero Under the Starlight',
//         posterAssetPath: 'assets/images/posters/hero_under_the_starlight.jpg',
//       ),