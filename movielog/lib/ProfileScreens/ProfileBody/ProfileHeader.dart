// 머리쪽

import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          padding: const EdgeInsets.all(30),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const CircleAvatar(
          radius: 68,
          backgroundImage: AssetImage(
            'assets/images/profile/profile_movielog.jpg',
          ),
        ),
        SizedBox(height: 11),
        Text(
          '무비러버',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            textAlign: TextAlign.center,
            '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16.3,
              color: AppColors.primary80,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
