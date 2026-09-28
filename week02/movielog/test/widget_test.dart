import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/theme/app_theme.dart';

void main() {
  testWidgets('StartScreen shows title and CTA button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const StartScreen()),
    );

    expect(find.text('시작하기'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('MovieLogApp opens the sign-up screen for week 2', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);
  });
}
