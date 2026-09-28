import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/signup_header.dart';
import '../widgets/signup_nickname_field.dart';
import '../widgets/signup_email_field.dart';
import '../widgets/signup_password_field.dart';
import '../widgets/signup_terms_checkbox.dart';
import '../widgets/signup_button.dart';
import '../widgets/signup_login_link.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // 닉네임
  final _nicknameController = TextEditingController();
  final _nicknameFocusNode = FocusNode();

  // 이메일
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  // 비밀번호
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  // 약관 동의
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // 버튼 활성화 조건: 세 입력값이 형식상 유효하고 약관에 동의했을 때만 true
  bool get _canSubmit {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final nicknameValid = nickname.length >= 2;
    final emailValid = _emailRegex.hasMatch(email);
    final passwordValid = password.length >= 8;

    return nicknameValid && emailValid && passwordValid && _agreedToTerms;
  }

  void _handleSubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // TODO: 실제 회원가입 API 연동은 이후 단계에서 진행합니다.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('가입 요청을 보냈습니다.')),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpHeader(),
                const SizedBox(height: 32),
                SignUpNicknameField(
                  controller: _nicknameController,
                  focusNode: _nicknameFocusNode,
                  onFieldSubmitted: () => _emailFocusNode.requestFocus(),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                SignUpEmailField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  onFieldSubmitted: () => _passwordFocusNode.requestFocus(),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                SignUpPasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  onFieldSubmitted: _handleSubmit,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                SignUpTermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() => _agreedToTerms = value ?? false);
                  },
                ),
                const SizedBox(height: 16),
                SignUpButton(
                  enabled: _canSubmit,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 16),
                SignUpLoginLink(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}