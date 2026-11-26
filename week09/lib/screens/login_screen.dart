import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/login_request.dart';
import '../data/services/auth_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authApiService =
          context.read<AuthApiService>();

      final response = await authApiService.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;

      if (response.isSuccess &&
          response.result != null) {
        context.go('/movies');
        return;
      }

      setState(() {
        _errorMessage = response.message;
      });
    } on DioException catch (error) {
      if (!mounted) return;

      final data = error.response?.data;

      String message = '로그인에 실패했습니다.';

      if (data is Map<String, dynamic>) {
        final serverMessage = data['message'];

        if (serverMessage is String &&
            serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            '로그인 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MovieLog 로그인',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '이메일과 비밀번호를 입력해 주세요.',
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText: '이메일',
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return '이메일을 입력해 주세요.';
                        }

                        if (!email.contains('@')) {
                          return '올바른 이메일 형식을 입력해 주세요.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _passwordController,
                      obscureText: true,
                      onFieldSubmitted: (_) {
                        _login();
                      },
                      decoration:
                          const InputDecoration(
                        labelText: '비밀번호',
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return '비밀번호를 입력해 주세요.';
                        }

                        return null;
                      },
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .error,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('로그인'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        context.go('/signup');
                      },
                      child:
                          const Text('회원가입하기'),
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