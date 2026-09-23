import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// 에러 상태 전용 색상 (M3 error 팔레트 기준)
const kSignUpErrorColor = Color(0xFFB3261E);
const kSignUpErrorFill = Color(0xFFF9DEDC);

/// 회원가입 화면 입력창들이 공통으로 쓰는 테두리/배경 스타일
InputDecoration buildSignUpFieldDecoration({
  required String hintText,
  required bool hasError,
}) {
  final normalBorderSide = BorderSide(color: AppColors.gray.withOpacity(0.3));
  const focusedBorderSide = BorderSide(color: AppColors.violet, width: 2);
  const errorBorderSide = BorderSide(color: kSignUpErrorColor);
  const focusedErrorBorderSide = BorderSide(color: kSignUpErrorColor, width: 2);

  OutlineInputBorder border(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: side,
      );

  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
    filled: true,
    fillColor: hasError ? kSignUpErrorFill : AppColors.white,
    suffixIcon: hasError
        ? const Icon(Icons.error_outline, color: kSignUpErrorColor)
        : null,
    border: border(hasError ? errorBorderSide : normalBorderSide),
    enabledBorder: border(hasError ? errorBorderSide : normalBorderSide),
    focusedBorder:
        border(hasError ? focusedErrorBorderSide : focusedBorderSide),
    errorBorder: border(errorBorderSide),
    focusedErrorBorder: border(focusedErrorBorderSide),
    errorStyle: AppTextStyles.bodySmall.copyWith(color: kSignUpErrorColor),
  );
}
