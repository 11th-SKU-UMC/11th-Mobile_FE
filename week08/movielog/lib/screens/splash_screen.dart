import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_spacing.dart';
import '../widgets/movielog_button.dart';

/// 앱 시작 시 세션을 확인하는 동안의 화면. (`/start`)
///
/// 1주차 StartScreen의 로고·제목·설명 레이아웃을 그대로 재사용하고,
/// 하단 '시작하기' 버튼 자리를 상태에 맞게 바꾼다.
/// - [onRetry]가 null: 세션 확인 중(initializing). 인디케이터를 보여준다.
/// - [onRetry]가 있음: 확인 실패(retryRequired). 문구와 다시 시도 버튼을 보여준다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  static const String defaultFailureMessage = '로그인 상태를 확인하지 못했어요.';

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onRetry = this.onRetry;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Text('FLUTTER 8주차'),
                  const SizedBox(height: 64),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 72,
                    height: 72,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (onRetry == null)
                Semantics(
                  label: '로그인 상태를 확인하는 중',
                  liveRegion: true,
                  child: const SizedBox(
                    height: 44,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else
                Column(
                  children: [
                    Text(
                      message ?? defaultFailureMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    MovieLogButton(
                      label: '다시 시도',
                      width: double.infinity,
                      onPressed: onRetry,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
