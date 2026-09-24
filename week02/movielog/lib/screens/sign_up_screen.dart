import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_spacing.dart';
import '../utils/validators.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/login_prompt.dart';
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

  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  /// 버튼 활성화 조건. 각 입력창의 validator와 같은 규칙을 그대로 쓴다.
  bool get _canSubmit =>
      Validators.nickname(_nicknameController.text) == null &&
      Validators.email(_emailController.text) == null &&
      Validators.password(_passwordController.text) == null &&
      _agreedToTerms;

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
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, screen) {
        final isWide = screen.maxWidth >= _wideBreakpoint;

        return Scaffold(
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
      leading: IconButton(
        tooltip: '뒤로 가기',
        // 2주차에도 화면 이동은 연결하지 않습니다.
        onPressed: () {},
        icon: SvgPicture.asset(
          'assets/icons/arrow_back.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isWide) {
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
            onChanged: (_) => _refresh(),
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
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
            onChanged: (_) => _refresh(),
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
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
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                textStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              child: const Text('가입하기'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 2주차에도 화면 이동은 연결하지 않습니다.
          LoginPrompt(onLoginPressed: () {}),
          // 좁은 화면은 아래쪽 여백을 두고, 넓은 화면은 가운데 정렬이라 필요 없다.
          if (!isWide) const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
