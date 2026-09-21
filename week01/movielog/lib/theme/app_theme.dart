import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Figma Design System을 옮긴 [ThemeData] 모음.
abstract final class AppTheme {
  static const double _radius = 8;
  static const String _fontFamily = 'Manrope';

  static final ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  static final TextTheme _textTheme = const TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    fontFamily: _fontFamily,
    textTheme: _textTheme,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: AppColors.onSurface),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}
