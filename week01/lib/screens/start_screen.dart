import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 72,
                height: 72,
                semanticsLabel: 'MovieLog 로고',
              ),

              const SizedBox(height: 24),

              const Text(
                '영화의 순간을 기록하세요',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              const Text(
                '보고 싶은 영화부터 나만의 평점까지 한곳에서 관리해요',
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {},
                child: const Text('시작하기'),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}