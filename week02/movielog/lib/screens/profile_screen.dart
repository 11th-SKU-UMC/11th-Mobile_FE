import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/preferred_genre_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: ProfileHeader(
                  imagePath: 'assets/images/profile/profile_movielog.jpg',
                  nickname: '무비러버',
                  bio:
                      '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
                  onEditPressed: _onEditProfile,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      child: const StatItem(label: '본 영화', value: '342'),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: const StatItem(label: '평점', value: '4.2'),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: AppSpacing.xs),
                      child: const StatItem(label: '즐겨찾기', value: '58'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const PreferredGenreSection(genres: ['드라마', 'SF', '애니메이션']),
            ],
          ),
        ),
      ),
    );
  }

  static void _onEditProfile() {}
}
