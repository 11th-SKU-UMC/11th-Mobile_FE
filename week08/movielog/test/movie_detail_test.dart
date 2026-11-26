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
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

import 'support/fake_services.dart';

class _Detail {
  _Detail(this.ratings, this.auth, this.store);

  final FakeRatingApiService ratings;
  final AuthViewModel auth;
  final SessionRatingsStore store;
}

/// 로그인된 상태로 상세 화면을 띄운다. (상세 화면은 로그인 상태에서만 열린다)
Future<_Detail> _pumpDetail(
  WidgetTester tester, {
  TmdbMovieDto? initialMovie,
  FakeMovieDetailService? movies,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  final ratings = FakeRatingApiService();
  final auth = await signedInAuth();
  final store = SessionRatingsStore(auth);

  final router = GoRouter(
    initialLocation: '/movies/550',
    routes: [
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) =>
            MovieDetailLoader(movieId: 550, initialMovie: initialMovie),
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
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: store),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _Detail(ratings, auth, store);
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

Future<MovieDetailViewModel> _viewModel(FakeRatingApiService ratings) async {
  final auth = await signedInAuth();
  return MovieDetailViewModel(
    ratings,
    auth,
    SessionRatingsStore(auth),
    movie(550),
  );
}

void main() {
  testWidgets('extra가 없으면 TMDB 상세 API로 영화를 다시 조회한다', (tester) async {
    final movies = FakeMovieDetailService(
      (id) async => movie(id, title: '파이트 클럽'),
    );
    await _pumpDetail(tester, movies: movies);

    expect(movies.calls, [550]);
    expect(find.text('파이트 클럽'), findsOneWidget);
  });

  testWidgets('extra가 있으면 다시 조회하지 않는다', (tester) async {
    final movies = FakeMovieDetailService((id) async => movie(id));
    await _pumpDetail(
      tester,
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

  testWidgets('로그인 상태면 memberId 없이 평점 남기기가 활성화되고 회원가입 안내가 없다', (tester) async {
    await _pumpDetail(tester);

    expect(_rateButton(tester).onPressed, isNotNull);
    expect(find.text('회원가입'), findsNothing);
  });

  testWidgets('등록에 성공하면 TMDB id로 요청하고, 응답 Rating을 세션 목록에 넣고 Snackbar를 보여준다', (
    tester,
  ) async {
    final detail = await _pumpDetail(tester);

    await _rateFourStars(tester);
    await tester.enterText(find.byType(TextField), '재밌다');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final request = detail.ratings.createCalls.single;
    // body에는 memberId가 없다. 사용자는 Authorization 헤더로 식별한다.
    expect(request.toJson(), {'movieId': 550, 'score': 4, 'comment': '재밌다'});
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text(MovieDetailScreen.ratingSavedMessage), findsOneWidget);
    final saved = detail.store.ratings.single;
    expect(saved.rating.ratingId, 101);
    expect(saved.movie?.id, 550);
  });

  testWidgets('RATING409_1이면 Dialog를 닫고 Snackbar로 안내만 하며 로그인은 유지한다', (
    tester,
  ) async {
    final detail = await _pumpDetail(tester);
    detail.ratings.createHandler = (_) async =>
        throw commonError(409, 'RATING409_1', '이미 이 영화에 평점을 남기셨습니다.');

    await _rateFourStars(tester);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(
      find.text('이미 이 영화에 평점을 남겼어요. 마이페이지에서 기존 기록을 확인해 주세요.'),
      findsOneWidget,
    );
    expect(find.text(MovieDetailScreen.ratingSavedMessage), findsNothing);
    expect(detail.auth.status, AuthStatus.signedIn);
    expect(detail.store.ratings, isEmpty);
  });

  group('MovieDetailViewModel', () {
    test('AUTH401_4면 세션을 만료시키고 Dialog를 닫게 한다', () async {
      final ratings = FakeRatingApiService()
        ..createHandler = (_) async =>
            throw commonError(401, 'AUTH401_4', '토큰이 만료되었습니다.');
      final auth = await signedInAuth();
      final viewModel = MovieDetailViewModel(
        ratings,
        auth,
        SessionRatingsStore(auth),
        movie(550),
      );

      await expectLater(
        viewModel.createRating(score: 4),
        throwsA(isA<RatingDialogDismissed>()),
      );

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(viewModel.submitStatus, SubmitStatus.error);
    });

    test('DioException 외 예외도 submitting에 멈추지 않는다', () async {
      final ratings = FakeRatingApiService()
        ..createHandler = (_) async => throw StateError('평점 result가 없습니다.');
      final viewModel = await _viewModel(ratings);

      await expectLater(
        viewModel.createRating(score: 4),
        throwsA(isA<StateError>()),
      );

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.submitMessage, MovieDetailViewModel.unknownErrorMessage);
    });

    test('dispose 뒤에 끝난 등록은 상태를 바꾸지 않는다', () async {
      final completer = Completer<void>();
      final ratings = FakeRatingApiService()
        ..createHandler = (request) async {
          await completer.future;
          return rating(movieId: request.movieId);
        };
      final viewModel = await _viewModel(ratings);

      final pending = viewModel.createRating(score: 4);
      viewModel.dispose();
      completer.complete();

      await expectLater(pending, throwsA(isA<RatingDialogDismissed>()));
      expect(viewModel.submitStatus, SubmitStatus.submitting);
    });
  });
}
