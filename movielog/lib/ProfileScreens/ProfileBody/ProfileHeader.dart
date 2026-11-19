// 머리쪽
// 8주차: 하드코딩 닉네임 대신 GET me로 받은 닉네임·가입일·이메일을 표시합니다.

import 'package:flutter/material.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';

// Challenge: createdAt → "2026.10.10 가입"
String formatJoinedDate(DateTime createdAt) {
  final local = createdAt.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}.$month.$day 가입';
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.member});

  final MemberInfo member;

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
        const SizedBox(height: 11),
        Text(
          member.nickname,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formatJoinedDate(member.createdAt),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary80),
        ),
        const SizedBox(height: 2),
        Text(
          member.email,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary80),
        ),
      ],
    );
  }
}
