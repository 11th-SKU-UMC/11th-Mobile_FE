import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/bookmarks.svg',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 24,
            right: 16,
            bottom: 24,
            left: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProfileHeader(),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Expanded(child: StatItem(label: '본 영화', value: '342')),
                  SizedBox(width: 8),
                  Expanded(child: StatItem(label: '평점', value: '4.2')),
                  SizedBox(width: 8),
                  Expanded(child: StatItem(label: '즐겨찾기', value: '58')),
                ],
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerLeft,
                child: const Text('선호하는 장르', style: AppTextStyles.titleMedium),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: const Text('드라마'),
                      backgroundColor: AppColors.violet.withOpacity(0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Chip(
                      label: const Text('SF'),
                      backgroundColor: AppColors.violet.withOpacity(0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Chip(
                      label: const Text('애니메이션'),
                      backgroundColor: AppColors.violet.withOpacity(0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}