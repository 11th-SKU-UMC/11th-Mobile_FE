import 'package:flutter/material.dart';

import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/SignUpScreen/sign_up_screen.dart';

import 'package:go_router/go_router.dart';

// import 'package:movielog/router/app_router.dart';

/* class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '내 프로필',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.movie_outlined),
            Text('무비러버', style: AppTextStyles.titleLarge),
            Text(
              '평점 4.5',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                  const Text('FLUTTER 1주차'),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/register');
                  }, // 1주차에는 화면 이동을 연결하지 않습니다.
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      // ← 이거 추가
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // 숫자 작을수록 각짐, 0이면 완전 직각
                    ),
                  ),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
