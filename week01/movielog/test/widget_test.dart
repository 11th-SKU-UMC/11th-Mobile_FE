// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('StartScreen shows title and CTA button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('시작하기'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
