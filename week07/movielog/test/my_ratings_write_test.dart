import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/screens/learning_sign_up_required_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

import 'support/fake_services.dart';

const _memberId = 7;

MyRatingsViewModel _viewModel(FakeRatingApiService ratings) =>
    MyRatingsViewModel(
      ratings,
      FakeMovieDetailService((id) async => movie(id)),
      _memberId,
    );

void main() {
  group('MyRatingsViewModel 쓰기', () {
    test('수정 성공 뒤 목록을 다시 조회한다', () async {
      var list = [rating(ratingId: 1, score: 5, comment: '처음')];
      final ratings = FakeRatingApiService((_) async => list);
      final viewModel = _viewModel(ratings);
      await viewModel.load();

      ratings.updateHandler = () async {
        list = [rating(ratingId: 1, score: 2, comment: null)];
      };
      await viewModel.updateRating(ratingId: 1, score: 2, comment: null);

      expect(ratings.updateCalls.single, (
        ratingId: 1,
        score: 2,
        comment: null,
      ));
      expect(ratings.calls, 2);
      expect(viewModel.ratings.single.rating.score, 2);
      expect(viewModel.refreshWarning, isNull);
    });

    test('409는 재조회 없이 다시 던지고, 403은 목록을 맞춘 뒤 다시 던진다', () async {
      final ratings = FakeRatingApiService((_) async => [rating()]);
      final viewModel = _viewModel(ratings);
      await viewModel.load();

      ratings.updateHandler = () async =>
          throw commonError(409, 'COMMON409', '중복');
      await expectLater(
        viewModel.updateRating(ratingId: 1, score: 3),
        throwsA(anything),
      );
      expect(ratings.calls, 1);

      ratings.deleteHandler = () async =>
          throw commonError(403, 'COMMON403', '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');
      await expectLater(viewModel.deleteRating(1), throwsA(anything));
      expect(ratings.calls, 2);
      expect(viewModel.status, MyRatingsLoadStatus.success);
    });

    test('마지막 항목을 지우면 Empty가 된다', () async {
      var list = [rating()];
      final ratings = FakeRatingApiService((_) async => list)
        ..deleteHandler = () async => list = [];
      final viewModel = _viewModel(ratings);
      await viewModel.load();

      await viewModel.deleteRating(1);

      expect(ratings.deleteCalls, [1]);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test(
      '저장 성공 뒤 GET만 실패하면 던지지 않고 refreshWarning을 남기며, 재조회 성공 시 지운다',
      () async {
        var getFails = false;
        final ratings = FakeRatingApiService((_) async {
          if (getFails) throw dioError();
          return [rating()];
        });
        final viewModel = _viewModel(ratings);
        await viewModel.load();

        getFails = true;
        await viewModel.updateRating(ratingId: 1, score: 4, comment: '수정');

        expect(ratings.updateCalls, hasLength(1));
        expect(viewModel.status, MyRatingsLoadStatus.error);
        expect(
          viewModel.refreshWarning,
          MyRatingsViewModel.refreshFailedMessage,
        );

        getFails = false;
        await viewModel.load();
        expect(viewModel.status, MyRatingsLoadStatus.success);
        expect(viewModel.refreshWarning, isNull);
        // 재시도는 조회만 한다. 쓰기 요청은 다시 보내지 않는다.
        expect(ratings.updateCalls, hasLength(1));
      },
    );

    test('DioException 외 예외도 StateError로 실패를 알린다', () async {
      final ratings = FakeRatingApiService((_) async => [rating()])
        ..deleteHandler = () async => throw StateError('예상하지 못한 삭제 응답: 200');
      final viewModel = _viewModel(ratings);
      await viewModel.load();

      await expectLater(
        viewModel.deleteRating(1),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            MyRatingsViewModel.unknownWriteErrorMessage,
          ),
        ),
      );
    });

    test('dispose 뒤에 끝난 쓰기는 목록을 다시 읽지 않는다', () async {
      final completer = Completer<void>();
      final ratings = FakeRatingApiService((_) async => [rating()])
        ..updateHandler = () => completer.future;
      final viewModel = _viewModel(ratings);
      await viewModel.load();

      final pending = viewModel.updateRating(ratingId: 1, score: 2);
      viewModel.dispose();
      completer.complete();
      await pending;

      expect(ratings.calls, 1);
    });
  });

  group('MyRatingsScreen 수정·삭제', () {
    Future<FakeRatingApiService> pump(
      WidgetTester tester,
      List<RatingDto> Function() list,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final ratings = FakeRatingApiService((_) async => list());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider(
            create: (_) => _viewModel(ratings)..load(),
            child: const MyRatingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ratings;
    }

    testWidgets('수정을 누르면 기존 별점·코멘트가 채워진 Dialog가 열리고 저장 후 목록이 갱신된다', (
      tester,
    ) async {
      var list = [rating(ratingId: 1, score: 3, comment: '예전 후기')];
      final ratings = await pump(tester, () => list);
      expect(find.text('학습용 회원(memberId 7)의 평점입니다.'), findsOneWidget);

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

      ratings.updateHandler = () async {
        list = [rating(ratingId: 1, score: 3, comment: '새 후기')];
      };
      await tester.enterText(find.byType(TextField), '새 후기');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(ratings.updateCalls.single.comment, '새 후기');
      expect(find.text('새 후기'), findsOneWidget);
    });

    testWidgets('삭제 확인에서 취소하면 요청을 보내지 않는다', (tester) async {
      final ratings = await pump(tester, () => [rating()]);

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('평점을 삭제할까요?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(ratings.deleteCalls, isEmpty);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('삭제 중에는 Dialog가 닫히지 않고, 마지막 항목을 지우면 Empty가 된다', (tester) async {
      var list = [rating()];
      final completer = Completer<void>();
      final ratings = await pump(tester, () => list)
        ..deleteHandler = () async {
          await completer.future;
          list = [];
        };

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

      expect(ratings.deleteCalls, [1]);
      expect(find.byType(DeleteRatingDialog), findsNothing);
      expect(find.text('아직 등록된 평점이 없어요.'), findsOneWidget);
    });

    testWidgets('삭제가 403이면 Dialog에 서버 문구를 보여주고 다시 시도할 수 있다', (tester) async {
      final ratings = await pump(tester, () => [rating()]);
      ratings.deleteHandler = () async =>
          throw commonError(403, 'COMMON403', '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.'), findsOneWidget);
      expect(find.byType(DeleteRatingDialog), findsOneWidget);
      expect(find.text('삭제'), findsWidgets);
    });

    testWidgets('저장 성공 뒤 GET만 실패하면 Dialog는 닫히고 조회만 다시 시도할 수 있다', (
      tester,
    ) async {
      var getFails = false;
      final ratings = FakeRatingApiService((_) async {
        if (getFails) throw dioError();
        return [rating()];
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider(
            create: (_) => _viewModel(ratings)..load(),
            child: const MyRatingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      ratings.updateHandler = () async => getFails = true;
      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(
        find.text(MyRatingsViewModel.refreshFailedMessage),
        findsOneWidget,
      );

      getFails = false;
      await tester.tap(find.text('조회만 다시 시도'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(ratings.updateCalls, hasLength(1));
    });
  });

  testWidgets('학습용 memberId가 없으면 /my/ratings에서 회원가입 안내를 보여준다', (tester) async {
    final router = GoRouter(
      initialLocation: '/ratings',
      routes: [
        GoRoute(
          path: '/ratings',
          builder: (context, state) =>
              const LearningSignUpRequiredScreen(title: '내가 등록한 평점'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
  });
}
