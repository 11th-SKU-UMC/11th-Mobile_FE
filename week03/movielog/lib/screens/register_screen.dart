import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('회원가입'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              context.go('/home');
            },
            child: const Text('회원가입 완료'),
          ),
        ),
      ),
    );
  }
}
