import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/preferred_genre_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';
import '../widgets/tab_app_bar.dart';

/// 마이 탭(마이페이지).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TabAppBar(title: '내 프로필'),
      body: SafeArea(
        // 진입 항목이 늘어 작은 화면에서 넘치지 않도록 스크롤되게 한다.
        child: SingleChildScrollView(
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
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('내가 등록한 평점'),
                trailing: const Icon(Icons.chevron_right),
                // push: 마이페이지 위에 쌓아서 뒤로 가면 마이페이지로 돌아온다.
                onTap: () => context.push(AppRoutes.myRatings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _onEditProfile() {}
}
