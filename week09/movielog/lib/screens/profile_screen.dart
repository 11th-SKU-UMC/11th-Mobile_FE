import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/preferred_genre_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';
import '../widgets/tab_app_bar.dart';

/// 마이 탭(마이페이지).
///
/// GET me로 받은 닉네임·이메일·가입일을 [AuthViewModel.member]에서 구독해 보여준다.
/// 통계·선호 장르는 기존 디자인 예시 값이다. (v7 GET me에는 없다)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 프로필 수정 성공 시 updateMember()로 바뀐 값이 바로 다시 그려지도록 select로 구독한다.
    final member = context.select<AuthViewModel, MemberInfo?>(
      (auth) => auth.member,
    );

    return Scaffold(
      appBar: TabAppBar(
        title: '내 프로필',
        actions: [
          TextButton(
            // 토큰과 member를 지우면 Router가 /login으로 보낸다.
            onPressed: () => context.read<AuthViewModel>().logout(),
            child: const Text('로그아웃'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        // 진입 항목이 늘어 작은 화면에서 넘치지 않도록 스크롤되게 한다.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ProfileHeader(
                  imagePath: 'assets/images/profile/profile_movielog.jpg',
                  nickname: member?.nickname ?? '-',
                  email: member?.email,
                  joinedText: member == null
                      ? null
                      : formatJoinedDate(member.createdAt),
                  // 내 정보를 받은 뒤에만 수정 화면으로 들어갈 수 있다.
                  onEditPressed: member == null
                      ? null
                      : () => context.push(AppRoutes.profileEdit),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('내 즐겨찾기'),
                trailing: const Icon(Icons.chevron_right),
                // 내 정보(GET me)를 받은 뒤에만 들어갈 수 있다. (세션 구분에 email을 쓴다)
                enabled: member != null,
                onTap: () => context.push(AppRoutes.myFavorites),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
