import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

import 'support/fake_services.dart';

class _Fixture {
  _Fixture(this.ratings, this.auth, this.store, this.storage);

  final FakeRatingApiService ratings;
  final AuthViewModel auth;
  final SessionRatingsStore store;
  final MemoryTokenStorage storage;

  late final MyRatingsViewModel viewModel = MyRatingsViewModel(
    ratings,
    auth,
    store,
  );

  void seed(List<RatingDto> values) {
    for (final value in values.reversed) {
      store.add(value, null, sessionVersion: auth.sessionVersion);
    }
  }
}

/// 로그인된 세션에 [initial] 평점을 등록해 둔 상태.
Future<_Fixture> _fixture([List<RatingDto> initial = const []]) async {
  final storage = MemoryTokenStorage();
  final auth = await signedInAuth(storage: storage);
  final fixture = _Fixture(
    FakeRatingApiService(),
    auth,
    SessionRatingsStore(auth),
    storage,
  )..seed(initial);
  return fixture;
}

void main() {
  group('MyRatingsViewModel 쓰기', () {
    test('수정 성공 응답의 Rating으로 카드를 바꾸고 목록을 다시 조회하지 않는다', () async {
      final f = await _fixture([rating(ratingId: 1, score: 5, comment: '처음')]);

      await f.viewModel.updateRating(ratingId: 1, score: 2, comment: null);

      expect(f.ratings.updateCalls.single, (
        ratingId: 1,
        score: 2,
        comment: null,
      ));
      expect(f.viewModel.ratings.single.rating.score, 2);
      expect(f.viewModel.ratings.single.rating.comment, isNull);
    });

    test(
      'RATING409_1·RATING403_1은 Dialog를 닫게 하고 Snackbar 문구만 남기며 로그인을 유지한다',
      () async {
        final f = await _fixture([rating()]);

        f.ratings.updateHandler = (_, _, _) async =>
            throw commonError(409, 'RATING409_1', '중복');
        await expectLater(
          f.viewModel.updateRating(ratingId: 1, score: 3),
          throwsA(isA<RatingDialogDismissed>()),
        );
        expect(f.viewModel.takeSnackbarMessage(), isNotNull);

        f.ratings.deleteHandler = (_) async => throw commonError(
          403,
          'RATING403_1',
          '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
        );
        await expectLater(
          f.viewModel.deleteRating(1),
          throwsA(isA<RatingDialogDismissed>()),
        );
        expect(
          f.viewModel.takeSnackbarMessage(),
          '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.',
        );
        expect(f.auth.status, AuthStatus.signedIn);
        expect(f.storage.token, testToken);
        expect(f.viewModel.ratings, hasLength(1));
      },
    );

    test('마지막 항목을 지우면(200) 빈 목록이 된다', () async {
      final f = await _fixture([rating()]);

      await f.viewModel.deleteRating(1);

      expect(f.ratings.deleteCalls, [1]);
      expect(f.viewModel.ratings, isEmpty);
    });

    test('AUTH401_2/3/4면 세션을 만료시켜 토큰과 목록을 지운다', () async {
      final f = await _fixture([rating()]);
      f.ratings.updateHandler = (_, _, _) async =>
          throw commonError(401, 'AUTH401_4', '토큰이 만료되었습니다.');

      await expectLater(
        f.viewModel.updateRating(ratingId: 1, score: 4, comment: '수정'),
        throwsA(isA<RatingDialogDismissed>()),
      );

      expect(f.auth.status, AuthStatus.signedOut);
      expect(f.auth.sessionExpired, isTrue);
      expect(f.storage.token, isNull);
      expect(f.viewModel.ratings, isEmpty);
    });

    test('DioException 외 예외도 StateError로 실패를 알린다', () async {
      final f = await _fixture([rating()]);
      f.ratings.deleteHandler = (_) async =>
          throw StateError('예상하지 못한 삭제 응답: 204');

      await expectLater(
        f.viewModel.deleteRating(1),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            MyRatingsViewModel.unknownWriteErrorMessage,
          ),
        ),
      );
    });

    test('로그아웃 뒤 늦게 끝난 쓰기는 오류 없이 무시되고 목록에 반영되지 않는다', () async {
      final f = await _fixture([rating(ratingId: 1, score: 5)]);
      final completer = Completer<void>();
      f.ratings.updateHandler = (ratingId, score, comment) async {
        await completer.future;
        return rating(ratingId: ratingId, score: score);
      };

      final pending = f.viewModel.updateRating(ratingId: 1, score: 2);
      await f.auth.logout();
      completer.complete();
      await pending;

      expect(f.viewModel.ratings, isEmpty);
    });
  });

  group('MyRatingsScreen 수정·삭제', () {
    Future<_Fixture> pump(WidgetTester tester, List<RatingDto> initial) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final f = await _fixture(initial);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider.value(
            value: f.viewModel,
            child: const MyRatingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return f;
    }

    testWidgets('수정을 누르면 기존 별점·코멘트가 채워진 Dialog가 열리고 저장 후 카드가 갱신된다', (
      tester,
    ) async {
      final f = await pump(tester, [
        rating(ratingId: 1, score: 3, comment: '예전 후기'),
      ]);
      expect(find.text(MyRatingsViewModel.sessionOnlyNotice), findsOneWidget);

      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.text('예전 후기'),
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '새 후기');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(f.ratings.updateCalls.single.comment, '새 후기');
      expect(find.text('새 후기'), findsOneWidget);
    });

    testWidgets('삭제 확인에서 취소하면 요청을 보내지 않는다', (tester) async {
      final f = await pump(tester, [rating()]);

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('평점을 삭제할까요?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(f.ratings.deleteCalls, isEmpty);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('삭제 중에는 Dialog가 닫히지 않고, 마지막 항목을 지우면 Empty가 된다', (tester) async {
      final completer = Completer<void>();
      final f = await pump(tester, [rating()]);
      f.ratings.deleteHandler = (_) => completer.future;

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pump();

      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteRatingDialog), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(f.ratings.deleteCalls, [1]);
      expect(find.byType(DeleteRatingDialog), findsNothing);
      expect(find.textContaining('이번 로그인에서 등록한 평점이 없어요.'), findsOneWidget);
    });

    testWidgets('삭제가 RATING403_1이면 Dialog를 닫고 Snackbar로 안내하며 카드는 남는다', (
      tester,
    ) async {
      final f = await pump(tester, [rating()]);
      f.ratings.deleteHandler = (_) async => throw commonError(
        403,
        'RATING403_1',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteRatingDialog), findsNothing);
      expect(find.text('본인이 작성한 평점만 수정하거나 삭제할 수 있어요.'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(f.auth.status, AuthStatus.signedIn);
    });

    testWidgets('수정이 RATING404_1이면 Dialog를 닫고 안내하며 카드를 목록에서 뺀다', (
      tester,
    ) async {
      final f = await pump(tester, [rating()]);
      f.ratings.updateHandler = (_, _, _) async =>
          throw commonError(404, 'RATING404_1', '존재하지 않는 평점입니다.');

      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(find.text('이미 삭제됐거나 존재하지 않는 평점이에요.'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });

  testWidgets('등록한 평점이 없으면 /my/ratings에서 세션 한정 안내와 빈 상태를 보여준다', (tester) async {
    final f = await _fixture();
    final router = GoRouter(
      initialLocation: '/ratings',
      routes: [
        GoRoute(
          path: '/ratings',
          builder: (context, state) => ChangeNotifierProvider.value(
            value: f.viewModel,
            child: const MyRatingsScreen(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    expect(find.text(MyRatingsViewModel.sessionOnlyNotice), findsOneWidget);
    expect(find.textContaining('이번 로그인에서 등록한 평점이 없어요.'), findsOneWidget);
  });
}
