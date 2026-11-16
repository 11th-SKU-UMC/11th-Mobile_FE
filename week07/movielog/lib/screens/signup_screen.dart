import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
import '../theme/app_text_styles.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/submit_status.dart';
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

  // 가입 가능 조건:
  // 로컬 입력 검증 통과 + 약관 동의 + 현재 닉네임·이메일의 중복 확인 available + 제출 중이 아님
  bool _canSubmit(SignUpViewModel viewModel) {
    final nickname = nicknameController.text.trim();
    final email = emailController.text.trim();
    final password = _passwordController.text;
    return nickname.length >= 2 &&
        _emailRegex.hasMatch(email) &&
        password.length >= 8 &&
        _agreedToTerms &&
        viewModel.isChecksPassed &&
        !viewModel.isSubmitting;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 비밀번호 입력창에서 Enter를 눌러도 약관 동의 없이는 넘어가지 않습니다.
    if (!_agreedToTerms) {
      _showMessage('필수 약관에 동의해주세요.');
      return;
    }

    final viewModel = context.read<SignUpViewModel>();
    if (viewModel.isSubmitting) return; // 연속 탭 방지
    // Enter로 제출해도 중복 확인을 통과하기 전에는 가입 요청을 보내지 않습니다.
    if (!viewModel.isChecksPassed) {
      _showMessage('닉네임과 이메일 중복 확인을 먼저 완료해 주세요.');
      return;
    }

    FocusScope.of(context).unfocus();
    await viewModel.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: _passwordController.text,
        nickname: nicknameController.text,
      ),
    );

    // await 뒤에는 화면이 아직 살아 있는지 다시 확인합니다.
    if (!mounted) return;

    final memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      // 가입 결과의 memberId를 학습용 세션에 보관한 뒤 영화 목록으로 이동합니다.
      context.read<LearningMemberSession>().setMemberId(memberId);
      context.go('/movies');
      return;
    }

    final message = viewModel.snackbarMessage;
    if (message != null) _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        // 제출 중에는 뒤로가기·스와이프 백을 막고, 끝나면(성공·실패) 다시 나갈 수 있습니다.
        return PopScope(
          canPop: !viewModel.isSubmitting,
          child: Scaffold(
            appBar: CommonAppBar(
              title: '회원가입',
              // pop()은 PopScope를 거치지 않으므로 maybePop()을 사용합니다.
              onBack: () => Navigator.of(context).maybePop(),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
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
                      if (viewModel.nicknameCheckStatus ==
                          CheckStatus.available)
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
                                ? () => viewModel.checkEmail(
                                    emailController.text,
                                  )
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
                        // 로컬 validator가 통과해도 서버(400)가 거부한 값이면 계속 에러로 보입니다.
                        errorText: viewModel.passwordErrorText,
                        onFieldSubmitted: _handleSubmit,
                        onChanged: () {
                          viewModel.onPasswordChanged();
                          setState(() {});
                        },
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
                        isLoading: viewModel.isSubmitting,
                        onPressed:
                            _canSubmit(viewModel) ? _handleSubmit : null,
                      ),
                      const SizedBox(height: 16),
                      SignUpLoginLink(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
