import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/widgets/movielog_button.dart';

// 8주차: 1주차 StartScreen 레이아웃을 재사용한 스플래시 화면입니다.
// onRetry == null → 세션 확인 중(initializing), onRetry != null → 확인 실패(retryRequired)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 32),
                  const Text('FLUTTER 8주차'),
                  const SizedBox(height: 64),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 72,
                    height: 72,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // 1주차 '시작하기' 버튼 자리를 로딩/재시도 상태로 대체합니다.
              if (onRetry == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                Column(
                  children: [
                    Text(
                      message ?? '로그인 상태를 확인하지 못했어요.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary80,
                      ),
                    ),
                    const SizedBox(height: 12),
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
