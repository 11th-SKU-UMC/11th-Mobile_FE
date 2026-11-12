import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

import 'support/fake_services.dart';

Future<FakeRatingApiService> _pumpDetail(
  WidgetTester tester, {
  int? memberId,
  TmdbMovieDto? initialMovie,
  FakeMovieDetailService? movies,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  final ratings = FakeRatingApiService((_) async => []);
  final session = LearningMemberSession();
  if (memberId != null) session.setMemberId(memberId);

  final router = GoRouter(
    initialLocation: '/movies/550',
    routes: [
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) =>
            MovieDetailLoader(movieId: 550, initialMovie: initialMovie),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(body: Text('가입 화면')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<RatingApiService>.value(value: ratings),
        Provider<TmdbMovieService>.value(
          value: movies ?? FakeMovieDetailService((id) async => movie(id)),
        ),
        ChangeNotifierProvider.value(value: session),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return ratings;
}

ButtonStyleButton _rateButton(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('평점 남기기'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

Future<void> _rateFourStars(WidgetTester tester) async {
  await tester.tap(find.text('평점 남기기'));
  await tester.pumpAndSettle();
  // RatingDialog의 MovieRatingInput(초기화 전 Key 0)에서 네 번째 별을 누른다.
  final stars = tester.getRect(find.byKey(const ValueKey(0)));
  await tester.tapAt(Offset(stars.left + stars.width * 0.7, stars.center.dy));
  await tester.pump();
}

void main() {
  testWidgets('extra가 없으면 TMDB 상세 API로 영화를 다시 조회한다', (tester) async {
    final movies = FakeMovieDetailService(
      (id) async => movie(id, title: '파이트 클럽'),
    );
    await _pumpDetail(tester, memberId: 7, movies: movies);

    expect(movies.calls, [550]);
    expect(find.text('파이트 클럽'), findsOneWidget);
  });

  testWidgets('extra가 있으면 다시 조회하지 않는다', (tester) async {
    final movies = FakeMovieDetailService((id) async => movie(id));
    await _pumpDetail(
      tester,
      memberId: 7,
      initialMovie: movie(550, title: '목록에서 넘긴 영화'),
      movies: movies,
    );

    expect(movies.calls, isEmpty);
    expect(find.text('목록에서 넘긴 영화'), findsOneWidget);
  });

  testWidgets('TMDB에 없는 영화(404)면 찾을 수 없음을 보여준다', (tester) async {
    await _pumpDetail(
      tester,
      movies: FakeMovieDetailService((id) async => null),
    );

    expect(find.text('영화를 찾을 수 없어요.'), findsOneWidget);
  });

  testWidgets('memberId가 없으면 평점 남기기가 비활성화되고 회원가입을 안내한다', (tester) async {
    await _pumpDetail(tester);

    expect(_rateButton(tester).onPressed, isNull);
    expect(find.text(MovieDetailScreen.signUpGuideMessage), findsOneWidget);

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(find.text('가입 화면'), findsOneWidget);
  });

  testWidgets('등록에 성공하면 TMDB id로 요청하고 Snackbar를 보여준다', (tester) async {
    final ratings = await _pumpDetail(tester, memberId: 7);
    expect(find.text(MovieDetailScreen.signUpGuideMessage), findsNothing);

    await _rateFourStars(tester);
    await tester.enterText(find.byType(TextField), '재밌다');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final request = ratings.createCalls.single;
    expect(request.movieId, 550);
    expect(request.score, 4);
    expect(request.comment, '재밌다');
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text(MovieDetailScreen.ratingSavedMessage), findsOneWidget);
  });

  testWidgets('409면 Dialog에 서버 문구를 보여주고 Snackbar는 띄우지 않는다', (tester) async {
    final ratings = await _pumpDetail(tester, memberId: 7);
    ratings.createHandler = () async =>
        throw commonError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.');

    await _rateFourStars(tester);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
    expect(find.text(MovieDetailScreen.ratingSavedMessage), findsNothing);
  });

  group('MovieDetailViewModel', () {
    test('memberId가 없으면 요청 없이 error', () async {
      final ratings = FakeRatingApiService((_) async => []);
      final viewModel = MovieDetailViewModel(ratings, null, movie(550));

      await viewModel.createRating(score: 4);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(
        viewModel.submitMessage,
        MovieDetailViewModel.signUpRequiredMessage,
      );
      expect(ratings.createCalls, isEmpty);
    });

    test('DioException 외 예외도 submitting에 멈추지 않는다', () async {
      final ratings = FakeRatingApiService((_) async => [])
        ..createHandler = () async => throw StateError('예상하지 못한 등록 응답: 200');
      final viewModel = MovieDetailViewModel(ratings, 7, movie(550));

      await viewModel.createRating(score: 4);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.submitMessage, MovieDetailViewModel.unknownErrorMessage);
    });

    test('dispose 뒤에 끝난 등록은 상태를 바꾸지 않는다', () async {
      final completer = Completer<void>();
      final ratings = FakeRatingApiService((_) async => [])
        ..createHandler = () => completer.future;
      final viewModel = MovieDetailViewModel(ratings, 7, movie(550));

      final pending = viewModel.createRating(score: 4);
      viewModel.dispose();
      completer.complete();
      await pending;

      expect(viewModel.submitStatus, SubmitStatus.submitting);
    });
  });
}
