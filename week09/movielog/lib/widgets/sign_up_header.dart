import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 회원가입 화면 상단 안내 영역.
///
/// 좁은 화면(휴대폰)은 앱바 아래에 환영 문구만 두고,
/// 넓은 화면은 앱바가 없으므로 제목과 부제를 함께 보여준다.
class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key, required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final descriptionStyle = textTheme.bodyLarge?.copyWith(
      color: colors.onSurfaceVariant,
    );

    if (!isWide) {
      return Text(
        '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
        textAlign: TextAlign.center,
        style: descriptionStyle,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '회원가입',
          style: textTheme.headlineMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Text('MovieLog에 오신 것을 환영합니다!', style: descriptionStyle),
      ],
    );
  }
}
