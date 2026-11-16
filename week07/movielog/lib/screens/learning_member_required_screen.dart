import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movielog_button.dart';

/// 학습용 회원가입 결과(memberId)가 없을 때 보여주는 안내 화면입니다.
/// 6주차처럼 memberId 1을 대신 쓰면 다른 회원의 path로 요청하게 되므로 막습니다.
class LearningMemberRequiredScreen extends StatelessWidget {
  const LearningMemberRequiredScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt, size: 40, color: AppColors.gray),
              const SizedBox(height: 12),
              const Text(
                '학습용 회원가입이 필요합니다.',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                '가입 결과로 받은 memberId는 앱을 재시작하면 사라집니다.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              MovieLogButton(
                label: '회원가입하러 가기',
                onPressed: () => context.go('/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
