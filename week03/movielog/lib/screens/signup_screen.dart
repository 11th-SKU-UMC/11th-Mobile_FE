import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // 입력 전 참고 화면도 약관 체크 상태로 표시되어 있습니다.
  bool _agreedToTerms = true;

  bool get _canSubmit {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    return nickname.length >= 2 &&
        emailPattern.hasMatch(email) &&
        password.length >= 8 &&
        _agreedToTerms;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth >= 700 ? 560 : double.infinity,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SignUpWelcome(),
                                const SizedBox(height: 48),
                                _SignUpFields(
                                  nicknameController: _nicknameController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  emailFocusNode: _emailFocusNode,
                                  passwordFocusNode: _passwordFocusNode,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TermsAgreement(
                                  value: _agreedToTerms,
                                  onChanged: (value) {
                                    setState(() => _agreedToTerms = value);
                                  },
                                ),
                                const SizedBox(height: 24),
                                _SignUpButton(
                                  enabled: _canSubmit,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 36),
                                const _LoginPrompt(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignUpWelcome extends StatelessWidget {
  const _SignUpWelcome();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.black),
    );
  }
}

class _SignUpFields extends StatelessWidget {
  const _SignUpFields({
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.onChanged,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final ValueChanged<String> onChanged;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  InputDecoration _decoration({
    required String hint,
    required String value,
    required bool isValid,
  }) {
    final hasInput = value.isNotEmpty;
    final hasError = hasInput && !isValid;
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCAC4D0)),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFB3261E)),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 16, color: AppColors.black),
      filled: true,
      fillColor: hasError ? const Color(0xFFFFDAD7) : const Color(0xFFF5F4F0),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      enabledBorder: hasError ? errorBorder : normalBorder,
      focusedBorder: hasError
          ? errorBorder
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.violet, width: 2),
            ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
      suffixIcon: !hasInput
          ? null
          : Icon(
              hasError ? Icons.error_outline : Icons.check_circle,
              color: hasError ? const Color(0xFFB3261E) : AppColors.violet,
              size: 24,
            ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('닉네임'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nicknameController,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '닉네임을 입력해주세요',
            value: nicknameController.text,
            isValid: nicknameController.text.trim().length >= 2,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
          validator: (value) {
            final nickname = value?.trim() ?? '';
            if (nickname.isEmpty) return '닉네임을 입력해주세요.';
            if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
            return null;
          },
        ),
        const SizedBox(height: 18),
        _label('이메일'),
        const SizedBox(height: 8),
        TextFormField(
          controller: emailController,
          focusNode: emailFocusNode,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '이메일 주소를 입력해주세요',
            value: emailController.text,
            isValid: _emailPattern.hasMatch(emailController.text.trim()),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return '이메일을 입력해주세요.';
            if (!_emailPattern.hasMatch(email)) {
              return '올바른 이메일 형식이 아닙니다.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        _label('비밀번호'),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '비밀번호를 입력해주세요',
            value: passwordController.text,
            isValid: passwordController.text.length >= 8,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          validator: (value) {
            final password = value ?? '';
            if (password.isEmpty) return '비밀번호를 입력해주세요.';
            if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
            return null;
          },
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      title: const Text(
        '필수 약관에 동의합니다',
        style: TextStyle(fontSize: 16, color: AppColors.black),
      ),
      activeColor: AppColors.violet,
      checkColor: AppColors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SignUpButton extends StatelessWidget {
  const _SignUpButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.violet,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: const Color(0xFFCCC2DB),
        disabledForegroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: const Text('가입하기'),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: '이미 계정이 있나요?  ',
        style: TextStyle(fontSize: 16, color: AppColors.gray),
        children: [
          TextSpan(
            text: '로그인',
            style: TextStyle(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
