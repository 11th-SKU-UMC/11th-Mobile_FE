// 공용 AppBar에서 조금 수정한 파일
// 8주차: 앱바 오른쪽 로그아웃 + 내 정보(GET me) 로딩·실패·재시도 상태

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/ProfileScreens/ProfileBody/profile_body.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    final Widget body;
    if (member != null) {
      body = ProfileBody(member: member);
    } else if (auth.memberStatus == MemberLoadStatus.error) {
      // Challenge: 실패 → 재시도 (로그아웃하지 않음)
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              auth.memberMessage ?? '내 정보를 불러오지 못했어요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary80,
              ),
            ),
            const SizedBox(height: 16),
            MovieLogButton(
              label: '다시 시도',
              width: 220,
              onPressed: () => auth.loadMember(force: true),
            ),
          ],
        ),
      );
    } else {
      // Challenge: MainScreen이 시작한 내 정보 로딩 중 → 화면 전체 인디케이터
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: member != null,
      appBar: CommonAppBar(
        title: '내 프로필',
        titleStyle: AppTextStyles.titleAppBar,
        actions: [
          TextButton(
            // 토큰과 member를 지우고 signedOut → Router가 /login으로 보냅니다.
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: Text(
              '로그아웃',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
    );
  }
}
