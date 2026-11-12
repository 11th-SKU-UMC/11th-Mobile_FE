import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 10,
    color: AppColors.textSecondary,
  );
}
