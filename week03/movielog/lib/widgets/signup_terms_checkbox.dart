import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 필수 약관 동의 체크박스
class SignUpTermsCheckbox extends StatelessWidget {
  const SignUpTermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.violet,
          ),
          Text('필수 약관에 동의합니다', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
