import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

import 'support/fake_services.dart';

/// 모든 요청을 [statusCode] 응답(또는 연결 실패)으로 거절하는 Dio.
Dio _rejectingDio({int? statusCode}) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: statusCode == null
                ? DioExceptionType.connectionError
                : DioExceptionType.badResponse,
            response: statusCode == null
                ? null
                : Response(requestOptions: options, statusCode: statusCode),
          ),
        ),
      ),
    );
}

/// 로그인 세션과 그 세션에서 등록한 평점 목록.
class _Session {
  _Session(this.auth, this.store);

  final AuthViewModel auth;
  final SessionRatingsStore store;

  void addRating(RatingDto value, {TmdbMovieDto? movie}) =>
      store.add(value, movie, sessionVersion: auth.sessionVersion);
}

Future<_Session> _session() async {
  final auth = await signedInAuth();
  return _Session(auth, SessionRatingsStore(auth));
}

void main() {
  group('RatingDto', () {
    test('응답 JSON을 그대로 옮기고 comment null을 허용한다', () {
      final dto = RatingDto.fromJson({
        'ratingId': 12,
        'movieId': 550,
        'score': 5,
        'comment': null,
        'createdAt': '2026-09-06T12:14:03.000Z',
        'updatedAt': '2026-09-06T12:14:03.000Z',
      });

      expect(dto.ratingId, 12);
      expect(dto.movieId, 550);
      expect(dto.score, 5);
      expect(dto.comment, isNull);
      expect(dto.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
    });
  });

  group('Service', () {
    test('목록 GET이 없어 RATING404_1은 재조회 대신 notFound(목록에서 빼기)로 처리한다', () {
      final notFound = commonError(404, 'RATING404_1', '존재하지 않는 평점입니다.');
      expect(ratingErrorAction(notFound), RatingErrorAction.notFound);
      expect(writeErrorMessage(notFound), '이미 삭제됐거나 존재하지 않는 평점이에요.');
    });

    test('findMovieById는 404만 null로 바꾼다', () async {
      expect(
        await TmdbMovieService(_rejectingDio(statusCode: 404)).findMovieById(1),
        isNull,
      );
      await expectLater(
        TmdbMovieService(_rejectingDio(statusCode: 500)).findMovieById(1),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        TmdbMovieService(_rejectingDio()).findMovieById(1),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('MyRatingsViewModel', () {
    test('현재 세션에서 등록 응답으로 받은 평점만, 최신 등록 순서로 보여준다', () async {
      final session = await _session();
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(),
        session.auth,
        session.store,
      );

      session.addRating(rating(ratingId: 1, movieId: 550), movie: movie(550));
      session.addRating(rating(ratingId: 2, movieId: 13), movie: movie(13));

      expect(viewModel.ratings.map((e) => e.rating.ratingId), [2, 1]);
      expect(viewModel.ratings.map((e) => e.movie?.title), ['영화 13', '영화 550']);
    });

    test('등록한 평점이 없으면 빈 목록이다 (서버 조회를 하지 않는다)', () async {
      final session = await _session();
      final ratings = FakeRatingApiService();
      final viewModel = MyRatingsViewModel(
        ratings,
        session.auth,
        session.store,
      );

      expect(viewModel.ratings, isEmpty);
      expect(ratings.createCalls, isEmpty);
      expect(ratings.updateCalls, isEmpty);
    });

    test('로그아웃하면 세션 평점 목록이 비워진다', () async {
      final session = await _session();
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(),
        session.auth,
        session.store,
      );
      session.addRating(rating());

      await session.auth.logout();

      expect(viewModel.ratings, isEmpty);
    });

    test('로그아웃 뒤 늦게 도착한 이전 세션의 등록 응답은 반영하지 않는다', () async {
      final session = await _session();
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(),
        session.auth,
        session.store,
      );
      final oldVersion = session.auth.sessionVersion;

      await session.auth.logout();
      await session.auth.login('movie@example.com', 'movie1234');
      session.store.add(rating(), null, sessionVersion: oldVersion);

      expect(viewModel.ratings, isEmpty);
    });

    test('회원 전환 뒤 늦게 끝난 수정은 새 세션 목록에 반영하지 않는다', () async {
      final session = await _session();
      final ratings = FakeRatingApiService();
      final viewModel = MyRatingsViewModel(
        ratings,
        session.auth,
        session.store,
      );
      session.addRating(rating(ratingId: 1, score: 5));
      final gate = Completer<void>();
      ratings.updateHandler = (ratingId, score, comment) async {
        await gate.future;
        return rating(ratingId: ratingId, score: score);
      };

      final pending = viewModel.updateRating(ratingId: 1, score: 2);
      await session.auth.logout();
      await session.auth.login('other@example.com', 'other1234');
      session.addRating(rating(ratingId: 1, score: 4));
      gate.complete();
      await pending;

      expect(viewModel.ratings.single.rating.score, 4);
    });

    test('dispose하면 세션 목록 변경 알림을 더 받지 않는다', () async {
      final session = await _session();
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(),
        session.auth,
        session.store,
      );
      var notified = 0;
      viewModel.addListener(() => notified++);
      viewModel.dispose();

      session.addRating(rating());

      expect(notified, 0);
    });
  });

  group('MyRatingsScreen', () {
    Future<_Session> pumpScreen(
      WidgetTester tester, {
      FakeRatingApiService? ratings,
      void Function(_Session session)? seed,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = await _session();
      seed?.call(session);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider(
            create: (_) => MyRatingsViewModel(
              ratings ?? FakeRatingApiService(),
              session.auth,
              session.store,
            ),
            child: const MyRatingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return session;
    }

    testWidgets('세션 평점을 그리고 재시작 복원 불가 안내를 보여준다. comment가 null이면 후기를 그리지 않는다', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        seed: (session) {
          session.addRating(
            rating(ratingId: 2, movieId: 13, score: 3, comment: null),
          );
          session.addRating(
            rating(movieId: 550, comment: '최고의 영화!'),
            movie: movie(550, title: '파이트 클럽'),
          );
        },
      );

      expect(find.text(MyRatingsViewModel.sessionOnlyNotice), findsOneWidget);
      expect(find.text('파이트 클럽'), findsOneWidget);
      expect(find.text('최고의 영화!'), findsOneWidget);
      // TMDB 정보가 없어도 평점은 남기고 placeholder로 보여준다.
      expect(find.text('영화 #13'), findsOneWidget);
      expect(find.text('movieId 13'), findsOneWidget);
      expect(find.text('2026.09.06'), findsNWidgets(2));
      // comment null 카드에는 후기 Text가 없다.
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));
      expect(
        find.descendant(of: cards.at(1), matching: find.byType(Text)),
        findsNWidgets(4), // 제목, movieId, 점수, 날짜
      );
    });

    testWidgets('Empty에도 재시작 복원 불가 안내를 보여준다', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('이번 로그인에서 등록한 평점이 없어요.'), findsOneWidget);
      expect(find.text(MyRatingsViewModel.sessionOnlyNotice), findsOneWidget);
    });

    testWidgets('400(COMMON400)은 Dialog 안에 서버 문구를 보여주고 입력을 유지한다', (
      tester,
    ) async {
      final ratings = FakeRatingApiService()
        ..updateHandler = (_, _, _) async =>
            throw commonError(400, 'COMMON400', '별점은 5점 이하여야 합니다.');
      final session = await pumpScreen(
        tester,
        ratings: ratings,
        seed: (session) => session.addRating(rating(score: 3)),
      );

      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsOneWidget);
      expect(find.text('별점은 5점 이하여야 합니다.'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(session.auth.status, AuthStatus.signedIn);
    });
  });

  testWidgets('마이페이지에서 진입하면 하단 탭이 가려지고 뒤로 가면 돌아온다', (tester) async {
    final session = await _session();
    final rootKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/my',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: '홈'),
                NavigationDestination(icon: Icon(Icons.person), label: '마이'),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'ratings',
                      parentNavigatorKey: rootKey,
                      builder: (context, state) => ChangeNotifierProvider(
                        create: (_) => MyRatingsViewModel(
                          FakeRatingApiService(),
                          session.auth,
                          session.store,
                        ),
                        child: const MyRatingsScreen(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session.auth,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();
    expect(find.byType(MyRatingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MyRatingsScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
