import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

/// 학습용 memberId가 없을 때(회원가입 전, 또는 앱 재시작 후) 보여주는 안내 화면.
class LearningSignUpRequiredScreen extends StatelessWidget {
  const LearningSignUpRequiredScreen({super.key, required this.title});

  static const String message = '학습용 회원가입이 필요합니다.';

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CommonAppBar(title: title, centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_outlined,
                size: 48,
                color: colors.outline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              MovieLogButton(
                label: '회원가입하러 가기',
                onPressed: () => context.push(AppRoutes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
