import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope', // 앱의 기본 Font Family

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, // #6750A4[cite: 1, 2]
      surface:
          AppColors.surface, // 또는 AppColors.warmWhite (#FAF9F5)[cite: 1, 2]
    ),

    scaffoldBackgroundColor: AppColors.warmWhite,
    // Scaffold의 기본 배경색
    appBarTheme: const AppBarTheme(
      // 모든 AppBar에 공통으로 적용할 스타일 ~~~(AppBarTheme)~~~
      backgroundColor: AppColors.warmWhite,
      foregroundColor: AppColors.black,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        // 상태바와 Android 시스템 Navigation Bar의 색상·아이콘 밝기를 설정
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.warmWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
  );
}
