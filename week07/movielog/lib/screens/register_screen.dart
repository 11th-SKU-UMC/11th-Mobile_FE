import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_text_form_field.dart';

final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? validateNickname(String? value) {
  final nickname = value?.trim() ?? '';
  if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
  if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해 주세요.';
  if (nickname.length > 12) return '닉네임은 12자 이하로 입력해 주세요.';
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '이메일을 입력해 주세요.';
  if (!_emailPattern.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
  return null;
}

/// 서버 규칙과 같은 기준입니다. 클라이언트 검증은 빠른 안내용이며 서버 검증을 대체하지 않습니다.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return '비밀번호를 입력해 주세요.';
  // 입력한 문자 자체를 trim으로 바꾸지 않고, 앞뒤 공백은 명확히 막습니다.
  if (password != password.trim()) return '비밀번호 앞뒤에 공백을 넣을 수 없습니다.';
  if (password.length < 8 ||
      !RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
    return '대문자/소문자/숫자/특수문자(!@#\$%^&*)를 포함한 8자 이상이어야 합니다.';
  }
  return null;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _canSubmit(SignUpViewModel viewModel) {
    return !viewModel.isSubmitting &&
        validateNickname(_nicknameController.text) == null &&
        validateEmail(_emailController.text) == null &&
        validatePassword(_passwordController.text) == null &&
        _agreedToTerms &&
        viewModel.isAllChecked;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    final viewModel = context.read<SignUpViewModel>();
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;

    final memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      // 가입 결과의 memberId를 학습용 세션에 보관해 이후 평점 요청에 사용합니다.
      context.read<LearningMemberSession>().setMemberId(memberId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입을 완료했어요. (memberId $memberId)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // go로 이동해 영화 목록에서 회원가입 화면으로 뒤로 가지 않도록 합니다.
      context.go('/movies');
      return;
    }

    final message = viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 제출 중에는 뒤로가기·스와이프 백으로 화면을 벗어나지 못하게 합니다.
    final isSubmitting = context.select<SignUpViewModel, bool>(
      (viewModel) => viewModel.isSubmitting,
    );

    return PopScope(
      canPop: !isSubmitting,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 넓은 화면에서는 Form을 가운데 두고 최대 너비를 560으로 제한합니다.
              final maxFormWidth = constraints.maxWidth >= 700
                  ? 560.0
                  : double.infinity;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Consumer<SignUpViewModel>(
                        builder: (context, viewModel, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SignUpHeader(),
                              const SizedBox(height: 32),
                              _DuplicateCheckField(
                                field: MovieLogTextFormField(
                                  controller: _nicknameController,
                                  focusNode: _nicknameFocusNode,
                                  label: '닉네임',
                                  hint: '2~12자 입력',
                                  enabled: !viewModel.isSubmitting,
                                  prefixIcon: Icons.person_outline,
                                  validator: validateNickname,
                                  errorText: viewModel.nicknameErrorText,
                                  helperText:
                                      viewModel.nicknameCheckStatus ==
                                          CheckStatus.available
                                      ? '사용할 수 있는 닉네임입니다.'
                                      : null,
                                  suffixIcon: _CheckIcon(
                                    status: viewModel.nicknameCheckStatus,
                                  ),
                                  onChanged: viewModel.onNicknameChanged,
                                  onFieldSubmitted: (_) =>
                                      _emailFocusNode.requestFocus(),
                                ),
                                button: MovieLogButton(
                                  label: '중복 확인',
                                  isLoading:
                                      viewModel.nicknameCheckStatus ==
                                      CheckStatus.checking,
                                  onPressed:
                                      viewModel.canCheckNickname &&
                                          validateNickname(
                                                _nicknameController.text,
                                              ) ==
                                              null
                                      ? () => viewModel.checkNickname(
                                          _nicknameController.text,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _DuplicateCheckField(
                                field: MovieLogTextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: '이메일',
                                  hint: 'example@umc.com',
                                  enabled: !viewModel.isSubmitting,
                                  prefixIcon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: validateEmail,
                                  errorText: viewModel.emailErrorText,
                                  helperText:
                                      viewModel.emailCheckStatus ==
                                          CheckStatus.available
                                      ? '사용할 수 있는 이메일입니다.'
                                      : null,
                                  suffixIcon: _CheckIcon(
                                    status: viewModel.emailCheckStatus,
                                  ),
                                  onChanged: viewModel.onEmailChanged,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                ),
                                button: MovieLogButton(
                                  label: '중복 확인',
                                  isLoading:
                                      viewModel.emailCheckStatus ==
                                      CheckStatus.checking,
                                  onPressed:
                                      viewModel.canCheckEmail &&
                                          validateEmail(
                                                _emailController.text,
                                              ) ==
                                              null
                                      ? () => viewModel.checkEmail(
                                          _emailController.text,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              MovieLogTextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                label: '비밀번호',
                                hint: '대·소문자, 숫자, 특수문자 포함 8자 이상',
                                prefixIcon: Icons.lock_outline,
                                enabled: !viewModel.isSubmitting,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                validator: validatePassword,
                                // 로컬 validator가 통과해도 서버가 거부한 값이면 계속 에러로 보입니다.
                                errorText: viewModel.passwordErrorText,
                                onChanged: (_) {
                                  viewModel.onPasswordChanged();
                                  setState(() {});
                                },
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? '비밀번호 표시'
                                      : '비밀번호 숨기기',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _TermsAgreement(
                                value: _agreedToTerms,
                                onChanged: viewModel.isSubmitting
                                    ? null
                                    : (value) => setState(
                                        () => _agreedToTerms = value,
                                      ),
                              ),
                              const SizedBox(height: 24),
                              MovieLogButton(
                                label: '가입하기',
                                width: double.infinity,
                                height: 48,
                                isLoading: viewModel.isSubmitting,
                                onPressed: _canSubmit(viewModel)
                                    ? _submit
                                    : null,
                              ),
                              if (!viewModel.isAllChecked) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  '닉네임과 이메일 중복 확인을 완료해 주세요.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회원가입',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 8),
        Text('MovieLog에서 나만의 영화 기록을 시작해 보세요.', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

/// 입력창과 중복 확인 버튼을 Row의 별도 형제로 두고 8px 간격을 줍니다.
class _DuplicateCheckField extends StatelessWidget {
  const _DuplicateCheckField({required this.field, required this.button});

  final Widget field;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        // width를 전달하지 않아 내용 기반 크기를 사용합니다.
        button,
      ],
    );
  }
}

/// 확인 결과는 입력창 내부의 아이콘으로만 표시해 버튼과 겹치지 않게 합니다.
class _CheckIcon extends StatelessWidget {
  const _CheckIcon({required this.status});

  final CheckStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      CheckStatus.available => const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 20,
      ),
      CheckStatus.duplicated || CheckStatus.error => const Icon(
        Icons.error_outline,
        color: AppColors.error,
        size: 20,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});

  final bool value;

  /// null이면 제출 중이라 바꿀 수 없는 상태입니다.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged == null
                ? null
                : (checked) => onChanged(checked ?? false),
          ),
          const Expanded(
            child: Text(
              '(필수) 서비스 이용약관 및 개인정보 처리방침에 동의합니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
