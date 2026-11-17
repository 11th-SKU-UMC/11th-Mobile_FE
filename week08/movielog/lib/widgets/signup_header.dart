import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// 회원가입 화면 상단 환영 문구
class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '환영합니다!',
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
