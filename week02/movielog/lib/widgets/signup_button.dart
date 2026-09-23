import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 가입하기 버튼 (조건 충족 시에만 활성화)
class SignUpButton extends StatelessWidget {
  const SignUpButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          disabledBackgroundColor: AppColors.violet.withOpacity(0.4),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '가입하기',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
