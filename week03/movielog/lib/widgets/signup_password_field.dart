import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'signup_field_decoration.dart';

/// 비밀번호 입력창 (8자 이상 검증)
class SignUpPasswordField extends StatelessWidget {
  const SignUpPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onFieldSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;
  final VoidCallback onChanged;

  static String? validate(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (password.length < 8) {
      return '비밀번호는 8자 이상 입력해주세요.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        controller.text.isNotEmpty && validate(controller.text) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('비밀번호', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: AppTextStyles.bodyMedium,
          obscureText: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: buildSignUpFieldDecoration(
            hintText: '비밀번호를 입력해주세요',
            hasError: hasError,
          ),
          textInputAction: TextInputAction.done,
          validator: validate,
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        ),
      ],
    );
  }
}
