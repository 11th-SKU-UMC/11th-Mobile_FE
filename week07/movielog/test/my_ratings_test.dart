import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
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
    test('writeMyRatingsErrorMessage는 400/404/그 외를 구분한다', () {
      expect(
        writeMyRatingsErrorMessage(dioError(statusCode: 400)),
        'memberId 형식을 다시 확인해 주세요.',
      );
      expect(
        writeMyRatingsErrorMessage(dioError(statusCode: 404)),
        '존재하지 않는 회원입니다.',
      );
      expect(
        writeMyRatingsErrorMessage(dioError()),
        '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
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
    test('평점과 TMDB 영화를 묶고, 같은 movieId는 한 번만 조회한다', () async {
      final movies = FakeMovieDetailService((id) async => movie(id));
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(
          (_) async => [
            rating(ratingId: 1, movieId: 550),
            rating(ratingId: 2, movieId: 550),
            rating(ratingId: 3, movieId: 13),
          ],
        ),
        movies,
        1,
      );

      await viewModel.load();
      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.message, isNull);
      expect(viewModel.ratings.map((e) => e.movie?.title), [
        '영화 550',
        '영화 550',
        '영화 13',
      ]);
      expect(movies.calls..sort(), [13, 550]);
    });

    test('빈 배열은 Empty다', () async {
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService((_) async => []),
        FakeMovieDetailService((id) async => movie(id)),
        1,
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('404는 Error와 회원 없음 문구다', () async {
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService((_) async => throw dioError(statusCode: 404)),
        FakeMovieDetailService((id) async => movie(id)),
        1,
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.error);
      expect(viewModel.message, '존재하지 않는 회원입니다.');
    });

    test('DioException 외 예외도 loading에 멈추지 않고 Error가 된다', () async {
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService((_) async => throw TypeError()),
        FakeMovieDetailService((id) async => movie(id)),
        1,
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.error);
      expect(viewModel.message, MyRatingsViewModel.unknownErrorMessage);
    });

    test('영화 조회가 실패해도 평점은 남고, 실패는 캐시하지 않아 다시 조회한다', () async {
      var fail = true;
      final movies = FakeMovieDetailService((id) async {
        if (id == 13) return null; // TMDB에 없는 영화(404)
        if (fail) throw dioError();
        return movie(id);
      });
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(
          (_) async => [rating(movieId: 550), rating(ratingId: 2, movieId: 13)],
        ),
        movies,
        1,
      );

      await viewModel.load();
      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.ratings, hasLength(2));
      expect(viewModel.ratings.every((e) => e.movie == null), isTrue);
      expect(viewModel.message, MyRatingsViewModel.missingMoviesMessage);

      fail = false;
      await viewModel.load();
      expect(viewModel.ratings.first.movie?.title, '영화 550');
      // 404(null)는 캐시되어 다시 묻지 않는다.
      expect(movies.calls.where((id) => id == 13), hasLength(1));
      expect(movies.calls.where((id) => id == 550), hasLength(2));
    });

    test('새 요청이 시작되면 이전 응답은 버린다', () async {
      final first = Completer<List<RatingDto>>();
      var call = 0;
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService((_) {
          call++;
          return call == 1 ? first.future : Future.value(<RatingDto>[]);
        }),
        FakeMovieDetailService((id) async => movie(id)),
        1,
      );

      final stale = viewModel.load();
      await viewModel.load();
      first.complete([rating()]);
      await stale;

      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });
  });

  group('MyRatingsScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      FakeRatingApiService ratings, {
      FakeMovieDetailService? movies,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider(
            create: (_) => MyRatingsViewModel(
              ratings,
              movies ?? FakeMovieDetailService((id) async => movie(id)),
              1,
            )..load(),
            child: const MyRatingsScreen(),
          ),
        ),
      );
    }

    testWidgets('Loading 다음 Success. comment가 null이면 후기를 그리지 않는다', (
      tester,
    ) async {
      final completer = Completer<List<RatingDto>>();
      await pumpScreen(
        tester,
        FakeRatingApiService((_) => completer.future),
        movies: FakeMovieDetailService(
          (id) async => id == 13 ? null : movie(id, title: '파이트 클럽'),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([
        rating(movieId: 550, comment: '최고의 영화!'),
        rating(ratingId: 2, movieId: 13, score: 3, comment: null),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('파이트 클럽'), findsOneWidget);
      expect(find.text('최고의 영화!'), findsOneWidget);
      expect(find.text('영화 정보를 찾을 수 없어요'), findsOneWidget);
      expect(find.text('movieId 13'), findsOneWidget);
      expect(find.text('2026.09.06'), findsNWidgets(2));
      expect(
        find.text(MyRatingsViewModel.missingMoviesMessage),
        findsOneWidget,
      );
      // comment null 카드에는 후기 Text가 없다: 화면의 후기는 하나뿐이다.
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));
      expect(
        find.descendant(of: cards.at(1), matching: find.byType(Text)),
        findsNWidgets(4), // 제목, movieId, 점수, 날짜
      );
    });

    testWidgets('Empty', (tester) async {
      await pumpScreen(tester, FakeRatingApiService((_) async => []));
      await tester.pumpAndSettle();

      expect(find.text('아직 등록된 평점이 없어요.'), findsOneWidget);
    });

    testWidgets('Error에는 고정 너비 160의 다시 시도 버튼이 있고 누르면 다시 불러온다', (tester) async {
      final ratings = FakeRatingApiService(
        (_) async => throw dioError(statusCode: 404),
      );
      await pumpScreen(tester, ratings);
      await tester.pumpAndSettle();

      expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
      expect(tester.getSize(find.byType(MovieLogButton)).width, 160);

      ratings.handler = (_) async => [];
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(ratings.calls, 2);
      expect(find.text('아직 등록된 평점이 없어요.'), findsOneWidget);
    });
  });

  testWidgets('마이페이지에서 진입하면 하단 탭이 가려지고 뒤로 가면 돌아온다', (tester) async {
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
                          FakeRatingApiService((_) async => []),
                          FakeMovieDetailService((id) async => movie(id)),
                          1,
                        )..load(),
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
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
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
