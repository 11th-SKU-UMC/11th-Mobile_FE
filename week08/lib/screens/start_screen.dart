import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/storage/secure_token_storage.dart';
import '../data/services/member_api_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() =>
      _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _restoreSession(),
    );
  }

  Future<void> _restoreSession() async {
    setState(() {
      _errorMessage = null;
    });

    final accessToken =
        await SecureTokenStorage.readAccessToken();

    if (!mounted) return;

    // 저장된 토큰 자체가 없으면 로그인 화면
    if (accessToken == null ||
        accessToken.isEmpty) {
      context.go('/login');
      return;
    }

    try {
      // 저장된 토큰이 실제로 유효한지 서버에서 검증
      final response =
          await context
              .read<MemberApiService>()
              .getMyInfo();

      if (!mounted) return;

      if (response.isSuccess &&
          response.result != null) {
        // 토큰 유효 → 로그인 화면 생략
        context.go('/movies');
        return;
      }

      await SecureTokenStorage
          .deleteAccessToken();

      if (!mounted) return;

      context.go('/login');
    } on DioException catch (error) {
      if (!mounted) return;

      // 만료/위조 등 인증 실패
      if (error.response?.statusCode == 401) {
        await SecureTokenStorage
            .deleteAccessToken();

        if (!mounted) return;

        context.go('/login');
        return;
      }

      // 인터넷 문제 등은 토큰을 삭제하지 않음
      setState(() {
        _errorMessage =
            '로그인 상태를 확인하지 못했습니다.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            '로그인 상태를 확인하지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: _errorMessage == null
                ? const Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.movie_creation_outlined,
                        size: 72,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'MovieLog',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                    ],
                  )
                : Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      FilledButton(
                        onPressed:
                            _restoreSession,
                        child:
                            const Text('다시 시도'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}