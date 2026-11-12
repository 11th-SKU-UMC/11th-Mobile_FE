import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../utils/validators.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/login_prompt.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_text_form_field.dart';
import '../widgets/sign_up_header.dart';
import '../widgets/terms_checkbox.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  /// 이 너비 이상이면 넓은 화면 레이아웃을 쓴다. 기기 종류가 아니라 사용할 수 있는 너비로 나눈다.
  static const double _wideBreakpoint = 700;
  static const double _maxFormWidth = 560;

  /// 중복 확인 버튼 높이. 테마의 입력창(isDense, 세로 여백 10) 높이에 맞춘다.
  static const double _fieldHeight = 40;

  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  /// 버튼 활성화 조건. 각 입력창의 validator와 같은 규칙에 더해
  /// 닉네임·이메일이 모두 서버에서 사용 가능으로 확인되어야 한다.
  bool _canSubmit(SignUpViewModel viewModel) =>
      Validators.nickname(_nicknameController.text) == null &&
      Validators.email(_emailController.text) == null &&
      Validators.password(_passwordController.text) == null &&
      _agreedToTerms &&
      viewModel.isBothAvailable;

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

  void _refresh() => setState(() {});

  void _submit() {
    // 버튼 활성화는 빠른 조건일 뿐이므로, 제출할 때 Form 전체를 다시 검증한다.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !context.read<SignUpViewModel>().isBothAvailable) return;

    // 6주차(v5)에는 회원가입 POST API가 없으므로 요청을 보내지 않고 홈으로만 이동한다.

    // 계정이 실제로 만들어지지 않으므로 '가입 완료' 같은 안내는 띄우지 않는다.
    FocusScope.of(context).unfocus();
    // go: 회원가입 화면을 Stack에서 없애고 홈으로 이동한다.
    // 홈에서 뒤로 가기를 눌러도 회원가입 화면으로 돌아오지 않는다.
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, screen) {
        final isWide = screen.maxWidth >= _wideBreakpoint;

        // 회원가입 화면에서는 뒤로 가기(Android 뒤로 가기 버튼, 제스처)를 막는다.
        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: isWide ? null : _buildAppBar(context),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) => Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? _maxFormWidth : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? AppSpacing.xl : AppSpacing.md,
                        vertical: isWide ? AppSpacing.xl : 0,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      // 좁은 화면에서는 내용이 짧아도 화면 높이만큼 늘려서
                      // 체크박스와 버튼을 아래쪽에 붙일 수 있게 한다.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: isWide ? 0 : viewport.maxHeight,
                        ),
                        child: IntrinsicHeight(child: _buildForm(isWide)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return CommonAppBar(
      title: '회원가입',
      centerTitle: true,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      // 3주차: 회원가입에서는 뒤로 갈 수 없으므로 뒤로 가기 버튼을 두지 않는다.
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildForm(bool isWide) {
    // 중복 확인 상태가 바뀌면 입력창 errorText와 버튼 상태를 함께 다시 그린다.
    final viewModel = context.watch<SignUpViewModel>();
    final fieldGap = SizedBox(height: isWide ? AppSpacing.lg : AppSpacing.md);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isWide) const SizedBox(height: AppSpacing.xl),
          SignUpHeader(isWide: isWide),
          SizedBox(
            height: isWide ? AppSpacing.xxl : AppSpacing.xl + AppSpacing.md,
          ),
          MovieLogTextFormField(
            label: '닉네임',
            hintText: isWide ? '영화로운 닉네임을 입력하세요' : '닉네임을 입력해주세요',
            controller: _nicknameController,
            focusNode: _nicknameFocusNode,
            textInputAction: TextInputAction.next,
            validator: Validators.nickname,
            onChanged: viewModel.onNicknameChanged,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            errorText: viewModel.nicknameErrorText,
            successText: viewModel.nicknameCheckStatus == CheckStatus.available
                ? '사용할 수 있는 닉네임입니다.'
                : null,
            // 입력창 옆 보조 버튼이므로 width를 주지 않고 내용 기반 크기를 쓴다.
            trailing: MovieLogButton(
              label: '중복 확인',
              height: _fieldHeight,
              isLoading: viewModel.nicknameCheckStatus == CheckStatus.checking,
              onPressed: viewModel.canCheckNickname
                  ? () => viewModel.checkNickname(_nicknameController.text)
                  : null,
            ),
          ),
          fieldGap,
          MovieLogTextFormField(
            label: isWide ? '이메일 주소' : '이메일',
            hintText: isWide ? 'example@movielog.com' : '이메일 주소를 입력해주세요',
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            onChanged: viewModel.onEmailChanged,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            errorText: viewModel.emailErrorText,
            successText: viewModel.emailCheckStatus == CheckStatus.available
                ? '사용할 수 있는 이메일입니다.'
                : null,
            trailing: MovieLogButton(
              label: '중복 확인',
              height: _fieldHeight,
              isLoading: viewModel.emailCheckStatus == CheckStatus.checking,
              onPressed: viewModel.canCheckEmail
                  ? () => viewModel.checkEmail(_emailController.text)
                  : null,
            ),
          ),
          fieldGap,
          MovieLogTextFormField(
            label: '비밀번호',
            hintText: isWide ? '영문, 숫자 포함 8자 이상' : '비밀번호를 입력해주세요',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            enableVisibilityToggle: isWide,
            textInputAction: TextInputAction.done,
            validator: Validators.password,
            onChanged: (_) => _refresh(),
            onFieldSubmitted: (_) => _passwordFocusNode.unfocus(),
          ),
          if (isWide) const SizedBox(height: AppSpacing.xl) else const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: TermsCheckbox(
              boxSize: isWide ? 20 : 24,
              value: _agreedToTerms,
              onChanged: (agreed) => setState(() => _agreedToTerms = agreed),
            ),
          ),
          SizedBox(height: isWide ? AppSpacing.xl : AppSpacing.lg),
          // Form 하단 버튼이므로 부모가 허용하는 최대 너비를 쓴다.
          MovieLogButton(
            label: '가입하기',
            width: double.infinity,
            height: 56,
            onPressed: _canSubmit(viewModel) ? _submit : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 로그인 화면은 아직 없으므로 연결하지 않는다.
          LoginPrompt(onLoginPressed: () {}),
          // 좁은 화면은 아래쪽 여백을 두고, 넓은 화면은 가운데 정렬이라 필요 없다.
          if (!isWide) const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
