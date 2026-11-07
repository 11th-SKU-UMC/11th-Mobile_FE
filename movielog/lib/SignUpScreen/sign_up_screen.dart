import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

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
  void initState() {
    super.initState();
  }

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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpViewModel>();

    final canSubmit =
        nicknameController.text.trim().length >= 2 &&
        emailController.text.contains('@') &&
        passwordController.text.length >= 8 &&
        agreedToTerms &&
        viewModel.nicknameCheckStatus == CheckStatus.available &&
        viewModel.emailCheckStatus == CheckStatus.available;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        title: Text(
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
                // 입력 위젯
                Text(
                  '닉네임',
                  textAlign: TextAlign.left,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary110,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                // 6주차: 입력창 + 중복 확인 버튼을 Row의 형제로 배치 (간격 8px)
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
                            horizontal: 16, // 좌우 여백
                            vertical: 10,
                          ),

                          labelText: '닉네임 입력해주세요.',
                          hintText: '두 글자 이상 입력',
                          // 6주차: 서버 중복 확인 결과를 Form 에러 상태로 연결
                          errorText: viewModel.nicknameErrorText,
                          suffixIcon:
                              viewModel.nicknameCheckStatus ==
                                  CheckStatus.available
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey),
                          ), // 박스 테두리
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ), // 포커스 박스 테두리
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ), // 값 오류 박스 테두리
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ), // 값 오류 박스 테두리
                        ),

                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final nickname = value?.trim() ?? '';

                          if (nickname.isEmpty) {
                            return '닉네임을 입력해주세요.';
                          }

                          if (nickname.length < 2) {
                            return '닉네임은 2자 이상이어야 합니다.';
                          }

                          return null;
                        },
                        // 6주차: 입력이 바뀌면 이전 확인 결과 무효화
                        onChanged: (value) {
                          viewModel.onNicknameChanged(value);
                          setState(() {});
                        },
                        onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 입력창 옆 보조 버튼: width null(내용 기반 크기)
                    MovieLogButton(
                      label: '중복 확인',
                      isLoading:
                          viewModel.nicknameCheckStatus == CheckStatus.checking,
                      onPressed: viewModel.canCheckNickname
                          ? () =>
                                viewModel.checkNickname(nicknameController.text)
                          : null,
                    ),
                  ],
                ),
                if (viewModel.nicknameCheckStatus == CheckStatus.checking)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '닉네임 사용 가능 여부를 확인 중입니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (viewModel.nicknameCheckStatus == CheckStatus.available)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '사용할 수 있는 닉네임입니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '이메일',
                  textAlign: TextAlign.left,
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
                            horizontal: 16, // 좌우 여백
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

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey),
                          ), // 박스 테두리
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ), // 포커스 박스 테두리
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ), // 값 오류 박스 테두리
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ), // 값 오류 박스 테두리
                        ),

                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return '이메일 주소를 입력해주세요.';
                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          if (!emailRegex.hasMatch(email)) {
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
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '이메일 사용 가능 여부를 확인 중입니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (viewModel.emailCheckStatus == CheckStatus.available)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '사용할 수 있는 이메일입니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '비밀번호',
                  textAlign: TextAlign.left,
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
                      horizontal: 16, // 좌우 여백
                      vertical: 10,
                    ),
                    labelText: '비밀번호를 입력해주세요.',
                    hintText: '8자 이상 입력',

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),

                      borderSide: BorderSide(color: Colors.grey),
                    ), // 박스 테두리
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ), // 포커스 박스 테두리
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red),
                    ), // 값 오류 박스 테두리
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ), // 값 오류 박스 테두리
                  ),

                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final password = value ?? '';

                    if (password.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }

                    if (password.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다.';
                    }

                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),

                const SizedBox(height: 200),

                Row(
                  children: [
                    Transform.scale(
                      // ← 체크박스를 감싸서 키우기
                      scale: 1.3,

                      child: Checkbox(
                        value: agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            agreedToTerms = value ?? false;
                          });
                        },
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary; // 체크됐을 때
                          }
                          return AppColors.white;
                        }), // 체크 안 됐을 때
                        side: BorderSide(color: AppColors.SecondaryScale300),
                      ),
                    ),
                    const Text(
                      '필수 약관에 동의합니다.',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // 6주차: Form 하단 버튼은 width: double.infinity(전체 너비)
                MovieLogButton(
                  label: '가입하기',
                  width: double.infinity,
                  onPressed: canSubmit
                      ? () {
                          final isValid =
                              formKey.currentState?.validate() ?? false;
                          if (!isValid) return;
                          FocusScope.of(context).unfocus();
                          context.go('/home');
                        }
                      : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                  children: [
                    Text(
                      '이미 계정이 있나요?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // 나중에 로그인 화면으로 이동하는 코드를 넣을 자리
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
    );
  }
}
