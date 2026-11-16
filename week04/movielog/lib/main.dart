import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 첫 화면과 화면 이동은 MaterialApp이 아니라 AppRouter의 GoRouter가 결정한다.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
