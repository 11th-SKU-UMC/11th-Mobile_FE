import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 하단 "이미 계정이 있나요? 로그인" 링크
class SignUpLoginLink extends StatelessWidget {
  const SignUpLoginLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('이미 계정이 있나요? ', style: AppTextStyles.bodyMedium),
        GestureDetector(
          onTap: onTap,
          child: Text(
            '로그인',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
