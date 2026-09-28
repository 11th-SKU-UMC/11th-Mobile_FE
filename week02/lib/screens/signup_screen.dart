import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  bool get _canSubmit {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    return nickname.length >= 2 &&
        email.isNotEmpty &&
        email.contains('@') &&
        password.length >= 8 &&
        _agreedToTerms;
  }

  void _refreshFormState() {
    setState(() {});
  }

  void _changeTerms(bool value) {
    setState(() {
      _agreedToTerms = value;
    });
  }

  void _submit() {
    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입 조건을 모두 만족했습니다.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const _SignupHeader(),

                        const SizedBox(height: 32),

                        _SignupFormFields(
                          nicknameController:
                              _nicknameController,
                          emailController:
                              _emailController,
                          passwordController:
                              _passwordController,
                          passwordFocusNode:
                              _passwordFocusNode,
                          onChanged: _refreshFormState,
                        ),

                        const SizedBox(height: 16),

                        _TermsAndSubmitSection(
                          agreedToTerms:
                              _agreedToTerms,
                          canSubmit: _canSubmit,
                          onTermsChanged:
                              _changeTerms,
                          onSubmit: _submit,
                        ),
                      ],
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

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MovieLog 시작하기',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '회원 정보를 입력해 주세요.',
        ),
      ],
    );
  }
}

class _SignupFormFields extends StatelessWidget {
  const _SignupFormFields({
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.onChanged,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nicknameController,
          onChanged: (_) {
            onChanged();
          },
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '닉네임',
            hintText: '닉네임을 입력해 주세요.',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return '닉네임을 입력해 주세요.';
            }

            if (value.trim().length < 2) {
              return '닉네임은 2자 이상 입력해 주세요.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: emailController,
          onChanged: (_) {
            onChanged();
          },
          keyboardType:
              TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: '이메일을 입력해 주세요.',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return '이메일을 입력해 주세요.';
            }

            if (!value.contains('@')) {
              return '올바른 이메일 형식을 입력해 주세요.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          onChanged: (_) {
            onChanged();
          },
          obscureText: true,
          textInputAction:
              TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '비밀번호',
            hintText: '비밀번호를 입력해 주세요.',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return '비밀번호를 입력해 주세요.';
            }

            if (value.length < 8) {
              return '비밀번호는 8자 이상 입력해 주세요.';
            }

            return null;
          },
        ),
      ],
    );
  }
}

class _TermsAndSubmitSection
    extends StatelessWidget {
  const _TermsAndSubmitSection({
    required this.agreedToTerms,
    required this.canSubmit,
    required this.onTermsChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final bool canSubmit;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: agreedToTerms,
          onChanged: (value) {
            onTermsChanged(value ?? false);
          },
          title: const Text(
            '이용약관에 동의합니다.',
          ),
          controlAffinity:
              ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed:
              canSubmit ? onSubmit : null,
          child: const Text('가입하기'),
        ),
      ],
    );
  }
}