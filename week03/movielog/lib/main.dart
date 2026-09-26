import 'package:flutter/material.dart';
import 'package:movielog/router/app_router.dart';

import 'theme/app_theme.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: AppRouter.router,
  );
}
