import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/movie.dart';
import 'package:movielog/main.dart';
import 'package:movielog/screens/start_screen.dart';
import 'package:movielog/theme/app_theme.dart';

void main() {
  testWidgets('StartScreen shows title and CTA button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const StartScreen()),
    );

    expect(find.text('시작하기'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('시작하기를 누르면 회원가입 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);
  });

  test('Mock 데이터: ID로 같은 영화를 찾고 장르로 필터링한다', () {
    expect(findMovieById(1)?.title, '별빛 아래 우리');
    expect(findMovieById(999), isNull);

    expect(filterMoviesByGenres(const []).length, movies.length);
    expect(
      filterMoviesByGenres(const ['SF']).every((movie) => movie.genre == 'SF'),
      isTrue,
    );
  });
}
