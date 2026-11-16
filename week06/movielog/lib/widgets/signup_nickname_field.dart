import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'signup_field_decoration.dart';

/// 닉네임 입력창 (2자 이상 검증)
class SignUpNicknameField extends StatelessWidget {
  const SignUpNicknameField({
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
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    if (nickname.length < 2) {
      return '닉네임은 두 글자 이상 입력해주세요.';
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
        Text('닉네임', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: AppTextStyles.bodyMedium,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: buildSignUpFieldDecoration(
            hintText: '닉네임을 입력해주세요',
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
