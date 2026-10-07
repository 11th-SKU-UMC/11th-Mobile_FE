import 'package:flutter/material.dart';
import 'package:movielog/ProfileScreens/ProfileBody/profile_screen.dart';
import 'package:movielog/theme/app_colors.dart';

import 'theme/app_theme.dart';

import 'package:movielog/start_screen.dart';

import 'package:movielog/SignUpScreen/sign_up_screen.dart';

import 'package:movielog/router/app_router.dart';

void main() => runApp(const MovieLogApp());

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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      title: 'MovieLog',
      // home: const StartScreen(),
      // home: const ProfileScreen(),
      // home: const SignUpScreen(),
      routerConfig: AppRouter.router,
    );
  }
}
