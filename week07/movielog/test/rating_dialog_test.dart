import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'support/fake_services.dart';

const _guide = '별을 눌러 평점을 선택해주세요';
const _resetLabel = '초기화하고 다시 선택하기';

class _DialogResult {
  bool? value;
  bool closed = false;
  final List<(int, String?)> submits = [];
}

/// Dialog를 띄우고, 닫힐 때 돌려준 값과 onSubmit 호출을 [_DialogResult]에 담는다.
Future<_DialogResult> _openDialog(
  WidgetTester tester, {
  int initialScore = 0,
  String? initialComment,
  Future<void> Function()? onSubmit,
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
                  initialScore: initialScore,
                  initialComment: initialComment,
                  onSubmit: (score, comment) async {
                    result.submits.add((score, comment));
                    await onSubmit?.call();
                  },
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

Finder get _confirmFinder => find.widgetWithText(MovieLogButton, '확인');

VoidCallback? _confirmOnPressed(WidgetTester tester) => tester
    .widget<ElevatedButton>(
      find.descendant(
        of: _confirmFinder,
        matching: find.byType(ElevatedButton),
      ),
    )
    .onPressed;

/// 네 번째 별을 누른다. (정수 모드라 4점)
Future<void> _tapFourthStar(WidgetTester tester) async {
  final bar = tester.getRect(find.byType(RatingBar));
  await tester.tapAt(Offset(bar.left + bar.width * 0.7, bar.center.dy));
  await tester.pump();
}

void main() {
  group('RatingDialog', () {
    testWidgets('별점을 고르기 전에는 코멘트를 입력해도 확인이 비활성화된다', (tester) async {
      await _openDialog(tester);

      expect(find.text('별빛 아래 우리'), findsOneWidget);
      expect(find.text(_guide), findsOneWidget);
      await tester.enterText(find.byType(TextField), '좋았어요');
      await tester.pump();
      expect(_confirmOnPressed(tester), isNull);

      await _tapFourthStar(tester);
      expect(find.text('4 / ${MovieRatingInput.maxRating}'), findsOneWidget);
      expect(_confirmOnPressed(tester), isNotNull);
    });

    testWidgets('정수 모드로 별 한 개 단위만 받는다', (tester) async {
      await _openDialog(tester);

      final bar = tester.widget<RatingBar>(find.byType(RatingBar));
      expect(bar.allowHalfRating, isFalse);
      expect(bar.minRating, 1);
    });

    testWidgets('확인하면 정수 점수와 trim된 코멘트로 onSubmit을 부르고 true로 닫힌다', (
      tester,
    ) async {
      final result = await _openDialog(tester);
      await _tapFourthStar(tester);
      await tester.enterText(find.byType(TextField), '  최고  ');

      await tester.tap(_confirmFinder);
      await tester.pumpAndSettle();

      expect(result.submits, [(4, '최고')]);
      expect(result.value, isTrue);
      expect(find.byType(RatingDialog), findsNothing);
    });

    testWidgets('코멘트가 비어 있으면 null로 보낸다', (tester) async {
      final result = await _openDialog(tester);
      await _tapFourthStar(tester);
      await tester.enterText(find.byType(TextField), '   ');

      await tester.tap(_confirmFinder);
      await tester.pumpAndSettle();

      expect(result.submits, [(4, null)]);
    });

    testWidgets('취소하면 onSubmit을 부르지 않고 false를 돌려준다', (tester) async {
      final result = await _openDialog(tester);
      await _tapFourthStar(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();

      expect(result.submits, isEmpty);
      expect(result.value, isFalse);
    });

    testWidgets('코멘트는 500자까지만 입력된다', (tester) async {
      await _openDialog(tester);

      await tester.enterText(find.byType(TextField), 'a' * 600);
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        hasLength(500),
      );
    });

    testWidgets('저장 중에는 인디케이터만 보이고, 뒤로가기·바깥 탭으로 닫히지 않는다', (tester) async {
      final completer = Completer<void>();
      final result = await _openDialog(
        tester,
        onSubmit: () => completer.future,
      );
      await _tapFourthStar(tester);
      await tester.tap(_confirmFinder);
      await tester.pump();

      // 저장 중에는 label 대신 인디케이터만 그린다.
      final confirm = find.byType(MovieLogButton);
      expect(_confirmFinder, findsNothing);
      expect(
        find.descendant(
          of: confirm,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.descendant(
                of: confirm,
                matching: find.byType(ElevatedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      // 바깥(barrier) 탭
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      // 시스템 뒤로가기
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(result.closed, isFalse);

      completer.complete();
      await tester.pumpAndSettle();
      expect(result.value, isTrue);
    });

    testWidgets('저장에 실패하면 닫히지 않고 서버 문구를 보여주며 입력이 남고 다시 시도할 수 있다', (
      tester,
    ) async {
      var fail = true;
      final result = await _openDialog(
        tester,
        onSubmit: () async {
          if (fail) {
            throw commonError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.');
          }
        },
      );
      await _tapFourthStar(tester);
      await tester.enterText(find.byType(TextField), '남길 말');

      await tester.tap(_confirmFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsOneWidget);
      expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
      expect(find.text('남길 말'), findsOneWidget);
      expect(find.text('4 / ${MovieRatingInput.maxRating}'), findsOneWidget);
      expect(_confirmOnPressed(tester), isNotNull);

      fail = false;
      await tester.tap(_confirmFinder);
      await tester.pumpAndSettle();
      expect(result.value, isTrue);
      expect(result.submits, hasLength(2));
    });

    testWidgets('수정할 때는 기존 별점·코멘트로 열리고, 초기화하면 다시 고를 수 있다', (tester) async {
      await _openDialog(tester, initialScore: 3, initialComment: '예전 후기');

      expect(find.text('3 / ${MovieRatingInput.maxRating}'), findsOneWidget);
      expect(find.text('예전 후기'), findsOneWidget);
      expect(_confirmOnPressed(tester), isNotNull);

      await tester.tap(find.text(_resetLabel));
      await tester.pump();
      expect(find.text(_guide), findsOneWidget);
      expect(_confirmOnPressed(tester), isNull);
    });

    testWidgets('기존 코멘트가 null이면 빈 칸으로 시작한다', (tester) async {
      await _openDialog(tester, initialScore: 5);

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
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
