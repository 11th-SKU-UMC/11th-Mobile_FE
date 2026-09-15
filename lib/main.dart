import 'package:flutter/material.dart';

void main() {
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Icon(
              Icons.movie_outlined,
            ),
            const Text(
              '영화의 순간을 기록하세요',
            ),
            const Text(
              '보고 싶은 영화부터 나만의 평점까지 한곳에서 관리해요',
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint('시작하기 버튼을 눌렀습니다.');
              },
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}