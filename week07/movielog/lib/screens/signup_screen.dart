import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../core/sign_up_validation.dart';
import '../data/models/create_member_request.dart';
import '../view_models/learning_member_session.dart';
import '../theme/app_text_styles.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

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

  bool _canSubmit(SignUpViewModel viewModel) {
    return _agreedToTerms && viewModel.canSubmit(_request);
  }

  CreateMemberRequest get _request => CreateMemberRequest(
    email: _emailController.text,
    password: _passwordController.text,
    nickname: _nicknameController.text,
  );

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<SignUpViewModel>();
    if (!_canSubmit(viewModel)) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    await viewModel.submit(_request);
    if (!mounted) return;
    final memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      context.read<LearningMemberSession>().setMemberId(memberId);
      context.go('/movies');
    } else if (viewModel.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(viewModel.snackbarMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpViewModel>();
    return PopScope(
      canPop: !viewModel.isSubmitting,
      child: AbsorbPointer(
        absorbing: viewModel.isSubmitting,
        child: Scaffold(
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
                      maxWidth: constraints.maxWidth >= 700
                          ? 560
                          : double.infinity,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _SignUpWelcome(),
                                    const SizedBox(height: 48),
                                    _SignUpFields(
                                      viewModel: viewModel,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _TermsAgreement(
                                      value: _agreedToTerms,
                                      onChanged: (value) {
                                        setState(() => _agreedToTerms = value);
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    MovieLogButton(
                                      label: '가입하기',
                                      isLoading: viewModel.isSubmitting,
                                      width: double.infinity,
                                      onPressed: _canSubmit(viewModel)
                                          ? _submit
                                          : null,
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
    required this.viewModel,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.onChanged,
  });

  final SignUpViewModel viewModel;
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
    String? errorText,
  }) {
    final hasInput = value.isNotEmpty;
    final hasError = errorText != null || (hasInput && !isValid);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: hasError ? errorBorder : normalBorder,
      focusedBorder: hasError
          ? errorBorder
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.violet, width: 2),
            ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorText: errorText,
      errorMaxLines: 2,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                enabled: !viewModel.isSubmitting,
                controller: nicknameController,
                style: const TextStyle(fontSize: 16, color: AppColors.black),
                decoration: _decoration(
                  hint: '닉네임을 입력해주세요',
                  value: nicknameController.text,
                  isValid: validateNickname(nicknameController.text) == null,
                  errorText: viewModel.nicknameErrorText,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                onChanged: viewModel.onNicknameChanged,
                onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
                validator: validateNickname,
              ),
            ),
            const SizedBox(width: 8),
            MovieLogButton(
              label: '중복 확인',
              isLoading: viewModel.nicknameCheckStatus == CheckStatus.checking,
              onPressed: viewModel.canCheckNickname
                  ? () => viewModel.checkNickname(nicknameController.text)
                  : null,
            ),
          ],
        ),
        if (viewModel.nicknameCheckStatus == CheckStatus.available) ...[
          const SizedBox(height: 4),
          const Text('사용할 수 있는 닉네임입니다.', style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 18),
        _label('이메일'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                enabled: !viewModel.isSubmitting,
                controller: emailController,
                focusNode: emailFocusNode,
                style: const TextStyle(fontSize: 16, color: AppColors.black),
                decoration: _decoration(
                  hint: '이메일 주소를 입력해주세요',
                  value: emailController.text,
                  isValid: _emailPattern.hasMatch(emailController.text.trim()),
                  errorText: viewModel.emailErrorText,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: viewModel.onEmailChanged,
                onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                validator: validateEmail,
              ),
            ),
            const SizedBox(width: 8),
            MovieLogButton(
              label: '중복 확인',
              isLoading: viewModel.emailCheckStatus == CheckStatus.checking,
              onPressed: viewModel.canCheckEmail
                  ? () => viewModel.checkEmail(emailController.text)
                  : null,
            ),
          ],
        ),
        if (viewModel.emailCheckStatus == CheckStatus.available) ...[
          const SizedBox(height: 4),
          const Text('사용할 수 있는 이메일입니다.', style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 18),
        _label('비밀번호'),
        const SizedBox(height: 8),
        TextFormField(
          enabled: !viewModel.isSubmitting,
          controller: passwordController,
          focusNode: passwordFocusNode,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '비밀번호를 입력해주세요',
            value: passwordController.text,
            isValid: validatePasswordFormat(passwordController.text) == null,
            errorText: viewModel.passwordErrorText,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            viewModel.onPasswordChanged();
            onChanged(value);
          },
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          validator: validatePasswordFormat,
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
