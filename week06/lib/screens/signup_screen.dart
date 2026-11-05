import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/signup_view_model.dart';
import '../widgets/movielog_button.dart';

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

  bool _agreedToTerms = false;

  bool get _canSubmit {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final vm = context.read<SignupViewModel>();

    return nickname.length >= 2 &&
        email.isNotEmpty &&
        email.contains('@') &&
        password.length >= 8 &&
        _agreedToTerms &&
        vm.isNicknameAvailable &&
        vm.isEmailAvailable;
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (isValid && _canSubmit) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode:
                    AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MovieLog 시작하기',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '회원 정보를 입력해 주세요.',
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nicknameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        hintText: '닉네임을 입력해 주세요.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        vm.onNicknameChanged(value);
                        setState(() {});
                      },
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

                    const SizedBox(height: 8),

                    MovieLogButton(
                      label: '닉네임 중복 확인',
                      isLoading:
                          vm.nicknameState ==
                              CheckState.loading,
                      width: double.infinity,
                      onPressed:
                          _nicknameController.text
                                  .trim()
                                  .length >=
                              2
                          ? () {
                              vm.checkNickname(
                                _nicknameController.text,
                              );
                            }
                          : null,
                    ),

                    const SizedBox(height: 8),

                    _CheckMessage(
                      state: vm.nicknameState,
                      availableMessage:
                          '사용 가능한 닉네임입니다.',
                      unavailableMessage:
                          '이미 사용 중인 닉네임입니다.',
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        hintText: '이메일을 입력해 주세요.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        vm.onEmailChanged(value);
                        setState(() {});
                      },
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

                    const SizedBox(height: 8),

                    MovieLogButton(
                      label: '이메일 중복 확인',
                      isLoading:
                          vm.emailState ==
                              CheckState.loading,
                      width: double.infinity,
                      onPressed:
                          _emailController.text
                                      .trim()
                                      .isNotEmpty &&
                                  _emailController.text
                                      .contains('@')
                              ? () {
                                  vm.checkEmail(
                                    _emailController.text,
                                  );
                                }
                              : null,
                    ),

                    const SizedBox(height: 8),

                    _CheckMessage(
                      state: vm.emailState,
                      availableMessage:
                          '사용 가능한 이메일입니다.',
                      unavailableMessage:
                          '이미 사용 중인 이메일입니다.',
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction:
                          TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        hintText: '비밀번호를 입력해 주세요.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
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

                    const SizedBox(height: 16),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms =
                              value ?? false;
                        });
                      },
                      title: const Text(
                        '이용약관에 동의합니다.',
                      ),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 24),

                    MovieLogButton(
                      label: '가입하기',
                      width: double.infinity,
                      onPressed:
                          _canSubmit ? _submit : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckMessage extends StatelessWidget {
  const _CheckMessage({
    required this.state,
    required this.availableMessage,
    required this.unavailableMessage,
  });

  final CheckState state;
  final String availableMessage;
  final String unavailableMessage;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case CheckState.available:
        return Text(
          availableMessage,
          style: const TextStyle(
            color: Colors.green,
          ),
        );

      case CheckState.unavailable:
        return Text(
          unavailableMessage,
          style: const TextStyle(
            color: Colors.red,
          ),
        );

      case CheckState.error:
        return const Text(
          '중복 확인 중 오류가 발생했습니다.',
          style: TextStyle(
            color: Colors.red,
          ),
        );

      case CheckState.idle:
      case CheckState.loading:
        return const SizedBox.shrink();
    }
  }
}