import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/profile/profile_movielog.jpg',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          '무비러버',
          style: AppTextStyles.titleLarge,
        ),

        const SizedBox(height: 8),

        const Text(
          '좋아하는 영화를 기록하고 있어요',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        SvgPicture.asset(
          'assets/icons/person.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColors.violet,
            BlendMode.srcIn,
          ),
          semanticsLabel: '프로필 아이콘',
        ),
      ],
    );
  }
}