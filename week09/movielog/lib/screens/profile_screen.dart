import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            icon: const Icon(Icons.logout),
          ),
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
        child: member == null
            ? Center(
                child: auth.memberStatus == MemberLoadStatus.error
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(auth.message ?? '내 정보를 불러오지 못했어요.'),
                          const SizedBox(height: 12),
                          MovieLogButton(
                            label: '다시 시도',
                            onPressed: () => auth.loadMember(force: true),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 24,
            right: 16,
            bottom: 24,
            left: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileHeader(
                nickname: member.nickname,
                email: member.email,
                joinedText: _joinedText(member.createdAt),
                onEdit: () => context.push('/my/profile/edit'),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Expanded(
                    child: StatItem(label: '본 영화', value: '342'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatItem(label: '평점', value: '4.2'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatItem(label: '즐겨찾기', value: '58'),
                  ),
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
                      backgroundColor: AppColors.violet.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Chip(
                      label: const Text('SF'),
                      backgroundColor: AppColors.violet.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Chip(
                      label: const Text('애니메이션'),
                      backgroundColor: AppColors.violet.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('내가 등록한 평점'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/ratings'),
              ),
              // 9주차: 내가 등록한 평점 행 아래에 내 즐겨찾기 행 (member가 준비된 뒤에만 보임)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('내 즐겨찾기'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/favorites'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "2026.10.10 가입" 형식
String _joinedText(DateTime createdAt) {
  final local = createdAt.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '${local.year}.$mm.$dd 가입';
}
