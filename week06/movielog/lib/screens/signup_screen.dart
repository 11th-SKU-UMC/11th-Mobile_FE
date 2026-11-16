import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_text_styles.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/signup_header.dart';
import '../widgets/signup_login_link.dart';
import '../widgets/signup_password_field.dart';
import '../widgets/signup_terms_checkbox.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // 모든 입력값이 형식상 유효하고 약관에 동의했을 때만 가입하기 버튼 활성화
  bool get _canSubmit {
    final nickname = nicknameController.text.trim();
    final email = emailController.text.trim();
    final password = _passwordController.text;
    return nickname.length >= 2 &&
        _emailRegex.hasMatch(email) &&
        password.length >= 8 &&
        _agreedToTerms;
  }

  // 이번 주차는 실제 가입 요청을 보내지 않고, 유효하면 홈으로 이동만 합니다.
  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 비밀번호 입력창에서 Enter를 눌러도 약관 동의 없이는 넘어가지 않습니다.
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요.')));
      return;
    }

    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Consumer<SignUpViewModel>(
              builder: (context, viewModel, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SignUpHeader(),
                    const SizedBox(height: 32),

                    // ── 닉네임 ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nicknameController,
                            decoration: InputDecoration(
                              labelText: '닉네임',
                              errorText: viewModel.nicknameErrorText,
                            ),
                            validator: (value) {
                              final nickname = value?.trim() ?? '';
                              if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
                              if (nickname.length < 2) {
                                return '닉네임은 두 글자 이상 입력해 주세요.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              viewModel.onNicknameChanged(value);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        MovieLogButton(
                          label: '중복 확인',
                          isLoading:
                              viewModel.nicknameCheckStatus ==
                              CheckStatus.checking,
                          onPressed: viewModel.canCheckNickname
                              ? () => viewModel.checkNickname(
                                  nicknameController.text,
                                )
                              : null,
                        ),
                      ],
                    ),
                    if (viewModel.nicknameCheckStatus == CheckStatus.available)
                      const Text(
                        '사용할 수 있는 닉네임입니다.',
                        style: AppTextStyles.bodySmall,
                      ),
                    const SizedBox(height: 16),

                    // ── 이메일 ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: '이메일',
                              errorText: viewModel.emailErrorText,
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return '이메일을 입력해 주세요.';
                              if (!_emailRegex.hasMatch(email)) {
                                return '올바른 이메일 형식이 아닙니다.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              viewModel.onEmailChanged(value);
                              setState(() {});
                            },
                            onFieldSubmitted: (_) =>
                                _passwordFocusNode.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MovieLogButton(
                          label: '중복 확인',
                          isLoading:
                              viewModel.emailCheckStatus ==
                              CheckStatus.checking,
                          onPressed: viewModel.canCheckEmail
                              ? () => viewModel.checkEmail(emailController.text)
                              : null,
                        ),
                      ],
                    ),
                    if (viewModel.emailCheckStatus == CheckStatus.available)
                      const Text(
                        '사용할 수 있는 이메일입니다.',
                        style: AppTextStyles.bodySmall,
                      ),
                    const SizedBox(height: 16),

                    // ── 비밀번호 / 약관 / 가입하기 (2주차 위젯 재사용) ──
                    SignUpPasswordField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      onFieldSubmitted: _handleSubmit,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    SignUpTermsCheckbox(
                      value: _agreedToTerms,
                      onChanged: (value) =>
                          setState(() => _agreedToTerms = value ?? false),
                    ),
                    const SizedBox(height: 16),

                    // ── 실제 가입하기 버튼: width: double.infinity ──
                    MovieLogButton(
                      label: '가입하기',
                      width: double.infinity,
                      onPressed: _canSubmit ? _handleSubmit : null,
                    ),
                    const SizedBox(height: 16),
                    SignUpLoginLink(onTap: () => Navigator.of(context).pop()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
