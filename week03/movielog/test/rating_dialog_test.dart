import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/rating_dialog.dart';

const _guide = '별을 눌러 평점을 선택해주세요';
const _resetLabel = '초기화하고 다시 선택하기';

/// Dialog를 띄우고, 닫힐 때 돌려준 값을 [_DialogResult]에 담는다.
Future<_DialogResult> _openDialog(
  WidgetTester tester, {
  double initialRating = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  final result = _DialogResult();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result.value = await RatingDialog.show(
                  context,
                  movieTitle: '별빛 아래 우리',
                  initialRating: initialRating,
                );
                result.closed = true;
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return result;
}

class _DialogResult {
  double? value;
  bool closed = false;
}

ElevatedButton _confirmButton(WidgetTester tester) => tester.widget<ElevatedButton>(
  find.widgetWithText(ElevatedButton, '확인'),
);

Future<void> _tapStars(WidgetTester tester) async {
  await tester.tap(find.byType(RatingBar));
  await tester.pump();
}

void main() {
  group('RatingDialog', () {
    testWidgets('별점을 고르기 전에는 안내 문구가 보이고 확인·초기화 버튼이 비활성화된다', (tester) async {
      await _openDialog(tester);

      expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      expect(find.text(_guide), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNull);
      expect(
        tester.widget<TextButton>(find.widgetWithText(TextButton, _resetLabel)).onPressed,
        isNull,
      );
    });

    testWidgets('별을 누르면 점수가 표시되고 확인 버튼이 활성화된다', (tester) async {
      await _openDialog(tester);

      await _tapStars(tester);

      expect(find.text(_guide), findsNothing);
      expect(find.textContaining('/ ${MovieRatingInput.maxRating}'), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('확인을 누르면 0.5 단위의 선택 점수를 돌려주고 닫힌다', (tester) async {
      final result = await _openDialog(tester);
      await _tapStars(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();

      expect(result.closed, isTrue);
      expect(result.value, isNotNull);
      expect(result.value, inInclusiveRange(0.5, 5));
      expect(result.value! * 2 % 1, 0, reason: '0.5 단위여야 한다');
      expect(find.byType(RatingDialog), findsNothing);
    });

    testWidgets('취소를 누르면 별점을 골랐어도 null을 돌려준다', (tester) async {
      final result = await _openDialog(tester);
      await _tapStars(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();

      expect(result.closed, isTrue);
      expect(result.value, isNull);
    });

    testWidgets('이전 평점으로 열리고, 초기화하면 다시 처음 상태로 돌아간 뒤 재선택할 수 있다', (tester) async {
      await _openDialog(tester, initialRating: 4);

      expect(find.text('4.0 / ${MovieRatingInput.maxRating}'), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.text(_resetLabel));
      await tester.pump();

      expect(find.text(_guide), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNull);

      await _tapStars(tester);
      expect(_confirmButton(tester).onPressed, isNotNull);
    });
  });

  group('MovieRatingIndicator', () {
    testWidgets('0.5 단위가 아닌 평균 평점도 읽기 전용으로 그린다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MovieRatingIndicator(rating: 4.3)),
        ),
      );

      final indicator = tester.widget<RatingBarIndicator>(
        find.byType(RatingBarIndicator),
      );
      expect(indicator.rating, 4.3);
      expect(find.byType(RatingBar), findsNothing);
    });
  });
}
