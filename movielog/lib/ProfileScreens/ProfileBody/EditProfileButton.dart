// 프로필 수정 버튼

import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 23),
        TextButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          ),
          child: Text(
            '프로필 수정',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 17,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 22),
      ],
    );
  }
}
