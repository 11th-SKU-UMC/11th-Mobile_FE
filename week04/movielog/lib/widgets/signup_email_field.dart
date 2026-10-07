import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'signup_field_decoration.dart';

/// 이메일 입력창 (형식 검증)
class SignUpEmailField extends StatelessWidget {
  const SignUpEmailField({
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

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static String? validate(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
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
        Text('이메일', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: AppTextStyles.bodyMedium,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: buildSignUpFieldDecoration(
            hintText: '이메일 주소를 입력해주세요',
            hasError: hasError,
          ),
          textInputAction: TextInputAction.next,
          validator: validate,
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        ),
      ],
    );
  }
}
