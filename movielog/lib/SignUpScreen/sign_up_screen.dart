import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';
import 'package:movielog/widgets/movielog_button.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// 8자 이상 + 소문자·대문자·숫자·특수문자(!@#$%^&*) 각각 1개 이상
String? validatePasswordFormat(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return '비밀번호를 입력해주세요.';
  if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
  if (!RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password) ||
      !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
    return '대문자·소문자·숫자·특수문자(!@#\$%^&*)를 각각 포함해 주세요.';
  }
  return null;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final nicknameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  bool agreedToTerms = false;

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nicknameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  // 7주차: 실제 v6 회원가입 POST
  Future<void> _onSubmitPressed() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final viewModel = context.read<SignUpViewModel>();
    await viewModel.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: passwordController.text,
        nickname: nicknameController.text,
      ),
    );
    if (!mounted) return;

    final memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      context.read<LearningMemberSession>().setMemberId(memberId);
      debugPrint('[회원가입] 성공 memberId=$memberId'); // 비밀번호는 기록하지 않음
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('회원가입 완료! memberId: $memberId')));
      context.go('/movies');
      return;
    }
    final message = viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  OutlineInputBorder _border(
    Color color, {
    double width = 1,
    double radius = 8,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpViewModel>();
    final nickname = nicknameController.text.trim();

    final canSubmit =
        nickname.length >= 2 &&
        nickname.length <= 12 &&
        _emailRegex.hasMatch(emailController.text.trim()) &&
        validatePasswordFormat(passwordController.text) == null &&
        agreedToTerms &&
        viewModel.nicknameCheckStatus == CheckStatus.available &&
        viewModel.emailCheckStatus == CheckStatus.available &&
        !viewModel.isSubmitting;

    // Challenge: 제출 중에는 뒤로가기·스와이프 백 차단
    return PopScope(
      canPop: !viewModel.isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.warmWhite,
          title: const Text(
            '회원가입',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '환영합니다! \n간단한 정보만 입력하고 시작해보세요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    '닉네임',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary110,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: nicknameController,
                          focusNode: nicknameFocusNode,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            labelText: '닉네임 입력해주세요.',
                            hintText: '2~12자 입력',
                            errorText: viewModel.nicknameErrorText,
                            suffixIcon:
                                viewModel.nicknameCheckStatus ==
                                    CheckStatus.available
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            enabledBorder: _border(Colors.grey, radius: 10),
                            focusedBorder: _border(Colors.blue, width: 2),
                            errorBorder: _border(Colors.red),
                            focusedErrorBorder: _border(Colors.red, width: 2),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final nickname = value?.trim() ?? '';
                            if (nickname.isEmpty) return '닉네임을 입력해주세요.';
                            if (nickname.length < 2 || nickname.length > 12) {
                              return '닉네임은 2~12자여야 합니다.';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            viewModel.onNicknameChanged(value);
                            setState(() {});
                          },
                          onFieldSubmitted: (_) =>
                              emailFocusNode.requestFocus(),
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
                  if (viewModel.nicknameCheckStatus == CheckStatus.checking)
                    _statusText('닉네임 사용 가능 여부를 확인 중입니다.', Colors.blue),
                  if (viewModel.nicknameCheckStatus == CheckStatus.available)
                    _statusText('사용할 수 있는 닉네임입니다.', Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    '이메일',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: emailController,
                          focusNode: emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            labelText: '이메일 주소를 입력해주세요.',
                            hintText: 'movie@umc.com',
                            errorText: viewModel.emailErrorText,
                            suffixIcon:
                                viewModel.emailCheckStatus ==
                                    CheckStatus.available
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            enabledBorder: _border(Colors.grey, radius: 10),
                            focusedBorder: _border(Colors.blue, width: 2),
                            errorBorder: _border(Colors.red),
                            focusedErrorBorder: _border(Colors.red, width: 2),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return '이메일 주소를 입력해주세요.';
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
                              passwordFocusNode.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MovieLogButton(
                        label: '중복 확인',
                        isLoading:
                            viewModel.emailCheckStatus == CheckStatus.checking,
                        onPressed: viewModel.canCheckEmail
                            ? () => viewModel.checkEmail(emailController.text)
                            : null,
                      ),
                    ],
                  ),
                  if (viewModel.emailCheckStatus == CheckStatus.checking)
                    _statusText('이메일 사용 가능 여부를 확인 중입니다.', Colors.blue),
                  if (viewModel.emailCheckStatus == CheckStatus.available)
                    _statusText('사용할 수 있는 이메일입니다.', Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    '비밀번호',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    obscureText: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      labelText: '비밀번호를 입력해주세요.',
                      hintText: '대·소문자, 숫자, 특수문자 포함 8자 이상',
                      // 7주차: 서버 400(비밀번호 형식)을 입력칸 에러로 표시
                      errorText: viewModel.passwordErrorText,
                      errorMaxLines: 2,
                      enabledBorder: _border(Colors.grey, radius: 10),
                      focusedBorder: _border(Colors.blue, width: 2),
                      errorBorder: _border(Colors.red),
                      focusedErrorBorder: _border(Colors.red, width: 2),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: validatePasswordFormat,
                    onChanged: (_) {
                      viewModel.onPasswordChanged();
                      setState(() {});
                    },
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                  const SizedBox(height: 200),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.3,
                        child: Checkbox(
                          value: agreedToTerms,
                          onChanged: (value) {
                            setState(() => agreedToTerms = value ?? false);
                          },
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return AppColors.white;
                          }),
                          side: const BorderSide(
                            color: AppColors.SecondaryScale300,
                          ),
                        ),
                      ),
                      const Text(
                        '필수 약관에 동의합니다.',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  MovieLogButton(
                    label: '가입하기',
                    width: double.infinity,
                    isLoading: viewModel.isSubmitting, // 제출 중 중복 탭 차단
                    onPressed: canSubmit ? _onSubmitPressed : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있나요?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // 나중에 로그인 화면으로 이동
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '로그인',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
