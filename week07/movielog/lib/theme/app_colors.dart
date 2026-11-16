import 'package:flutter/material.dart';

/// Figma Design System의 원본 색상값.
///
/// 여기 정의된 값만 디자인 소스와 1:1로 대응하며, [AppTheme]에서
/// [ColorScheme]/컴포넌트 테마로 매핑해 사용한다.
abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Secondary
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Tertiary
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  // Error
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  // Surface
  static const Color surface = Color(0xFFFAF9F5);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Outline
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // Disabled (2주차 회원가입 화면의 비활성 '가입하기' 버튼에서 확인한 값)
  static const Color primaryDisabled = Color(0xFFCCC2DC);
}
