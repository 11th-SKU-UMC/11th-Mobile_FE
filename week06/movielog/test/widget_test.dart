import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
