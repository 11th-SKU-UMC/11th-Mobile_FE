import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/rating_screen.dart';
import 'package:movielog/theme/app_theme.dart';

Future<void> _pumpRating(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const RatingScreen()),
  );
}

ElevatedButton _saveButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

void main() {
  testWidgets('별점을 고르기 전에는 안내 문구가 보이고 저장 버튼이 비활성화된다', (tester) async {
    await _pumpRating(tester);

    expect(find.text('별점을 선택해주세요'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('별점을 선택하면 선택한 점수가 보이고 저장 버튼이 활성화된다', (tester) async {
    await _pumpRating(tester);

    await tester.tap(find.byType(RatingBar));
    await tester.pump();

    expect(find.text('별점을 선택해주세요'), findsNothing);
    expect(find.textContaining('/ 5'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('저장 버튼을 누르면 선택한 평점을 안내한다', (tester) async {
    await _pumpRating(tester);
    await tester.tap(find.byType(RatingBar));
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.textContaining('점을 저장했어요'), findsOneWidget);
  });
}
