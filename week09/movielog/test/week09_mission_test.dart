import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/main.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'week08_regression_test.dart' as tools;

Map<String, dynamic> movie(int id, {String? title}) => {
  'id': id,
  'title': title ?? '영화 $id',
};

Map<String, dynamic> favorite(int id) => {
  'favoriteId': id + 1000,
  'movieId': id,
  'createdAt': '2026-09-06T12:14:03Z',
};

ResponseBody page(int number, List<int> ids, {int total = 3}) =>
    tools.jsonBody(200, {
      'page': number,
      'total_pages': total,
      'total_results': ids.length,
      'results': ids.map(movie).toList(),
    });

int pageNumber(RequestOptions request) =>
    request.queryParameters['page'] as int;

Dio client(tools.WorkbookAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  addTearDown(() => dio.close(force: true));
  return dio;
}

DioException offline(RequestOptions request) => DioException(
  requestOptions: request,
  type: DioExceptionType.connectionError,
);

void usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 930);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=fixture');
    SharedPreferences.setMockInitialValues({});
  });

  test('Discover keeps cards on a page failure, retries it and ignores an old genre', () async {
    final stalePage = Completer<ResponseBody>();
    final calls = <(String?, int)>[];
    var pageTwoAttempts = 0;
    final dio = client(
      tools.WorkbookAdapter((request) {
        final genre = request.queryParameters['with_genres'] as String?;
        final number = pageNumber(request);
        calls.add((genre, number));
        if (genre == '18') return page(number, [90], total: 1);
        if (number == 2 && ++pageTwoAttempts == 1) throw offline(request);
        if (number == 3) return stalePage.future;
        return page(number, number == 1 ? [1, 2] : [2, 3]);
      }),
    );
    final vm = PagedMoviesViewModel(TmdbMovieService(dio));
    addTearDown(vm.dispose);

    await vm.loadInitial();
    expect(calls, [(null, 1)]);
    await vm.loadNextPage();
    expect(vm.loadMoreError, isNotNull);
    expect(vm.movies.map((movie) => movie.id), [1, 2]);
    await vm.loadNextPage();
    expect(vm.movies.map((movie) => movie.id), [1, 2, 3]);
    final oldGenre = vm.loadNextPage();
    expect(vm.isLoadingMore, isTrue);
    final changed = vm.selectGenres([18]);
    expect(vm.movies, isEmpty);
    await changed;
    stalePage.complete(page(3, [99]));
    await oldGenre;
    expect(calls, [(null, 1), (null, 2), (null, 2), (null, 3), ('18', 1)]);
    expect(vm.movies.single.id, 90);
    expect(vm.isLoadingMore, isFalse);
    expect(vm.loadMoreError, isNull);
    expect(vm.hasMore, isFalse);
  });

  test(
    'Search skips blank terms and discards old errors and disposed results',
    () async {
      final slow = Completer<ResponseBody>();
      final afterDispose = Completer<ResponseBody>();
      final calls = <String>[];
      final dio = client(
        tools.WorkbookAdapter((request) {
          expect(request.path, '/search/movie');
          final query = request.queryParameters['query'] as String;
          calls.add(query);
          return switch (query) {
            'first' => slow.future,
            'second' => page(1, [42], total: 1),
            'third' => afterDispose.future,
            _ => throw StateError('Unexpected query'),
          };
        }),
      );
      final vm = PagedMoviesViewModel(TmdbMovieService(dio), searchMode: true);
      await vm.submitQuery(' ');
      expect(vm.phase, LoadPhase.idle);
      final first = vm.submitQuery('first');
      await vm.submitQuery(' second ');
      slow.complete(tools.jsonBody(500, {}));
      await first;
      expect(vm.phase, LoadPhase.ready);
      expect(vm.movies.single.id, 42);
      await vm.submitQuery('');
      expect(vm.movies, isEmpty);
      expect(vm.phase, LoadPhase.idle);
      final third = vm.submitQuery('third');
      vm.dispose();
      afterDispose.complete(page(1, [3]));
      await third;
      expect(calls, ['first', 'second', 'third']);
    },
  );

  test('Favorites reconcile 409 and 404 with GET and preserve state on transport failure', () async {
    final requests = <String>[];
    var status = false;
    var loseResponse = false;
    final api = FavoriteApiService(
      client(
        tools.WorkbookAdapter((request) {
          requests.add('${request.method} ${request.path}');
          if (request.method == 'GET') {
            return tools.response(200, {'isFavorite': status});
          }
          if (request.method == 'POST') {
            expect(request.data, {'movieId': 550});
            status = true;
            if (loseResponse) throw offline(request);
            return tools.response(409, null, error: 'FAVORITE409_1');
          }
          expect(request.path, '/v8/favorites/550');
          status = false;
          return tools.response(404, null, error: 'FAVORITE404_1');
        }),
      ),
    );
    final guard = SessionGuard()..update('a@example.test');
    final vm = FavoriteDetailViewModel(api, guard, 'a@example.test', 550);
    addTearDown(vm.dispose);

    await vm.refresh();
    expect(vm.isFavorite, isFalse);
    await vm.toggle();
    expect(vm.isFavorite, isTrue);
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    loseResponse = true;
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    expect(vm.errorMessage, isNotNull);
    await vm.toggle();
    expect(vm.isFavorite, isTrue);
    expect(requests, [
      'GET /v8/favorites/550',
      'POST /v8/favorites',
      'GET /v8/favorites/550',
      'DELETE /v8/favorites/550',
      'GET /v8/favorites/550',
      'POST /v8/favorites',
      'GET /v8/favorites/550',
    ]);
  });

  test(
    'Favorites enrich at most five at a time and retry just the failed card',
    () async {
      var inFlight = 0;
      var peak = 0;
      var fail = true;
      final requestedIds = <int>[];
      final gate = Completer<void>();
      final api = FavoriteApiService(
        client(
          tools.WorkbookAdapter(
            (_) => tools.response(
              200,
              List.generate(100, (index) => favorite(index + 1)),
            ),
          ),
        ),
      );
      final tmdb = TmdbMovieService(
        client(
          tools.WorkbookAdapter((request) async {
            final id = int.parse(request.uri.pathSegments.last);
            requestedIds.add(id);
            inFlight++;
            if (inFlight > peak) peak = inFlight;
            if (inFlight == 5 && !gate.isCompleted) gate.complete();
            await gate.future;
            inFlight--;
            return fail && id == 2
                ? tools.jsonBody(404, {})
                : tools.jsonBody(200, movie(id));
          }),
        ),
      );
      final guard = SessionGuard()..update('a@example.test');
      final vm = FavoritesViewModel(api, tmdb, guard, 'a@example.test');
      addTearDown(vm.dispose);

      await vm.refresh();
      expect(peak, 5);
      expect(
        vm.items.map((item) => item.favorite.movieId),
        List.generate(100, (i) => i + 1),
      );
      expect(vm.items[0].movie?.id, 1);
      expect(vm.items[1].movie, isNull);
      fail = false;
      requestedIds.clear();
      await vm.retryMovie(2);
      expect(requestedIds, [2]);
      expect(vm.items[1].movie?.id, 2);
      guard.update('b@example.test');
      expect(vm.items, isEmpty);
    },
  );

  test(
    'Expired favorite requests clear one current session and 403 does not',
    () async {
      final pending = <Completer<ResponseBody>>[];
      final pair = Completer<void>();
      final storage = tools.MemoryStorage('fixture-session');
      var denied = true;
      final fixture = tools.Fixture(
        storage,
        tools.WorkbookAdapter((request) {
          expect(request.headers['Authorization'], 'Bearer fixture-session');
          if (request.path == '/v8/members/me') {
            return tools.response(200, tools.member);
          }
          if (denied) return tools.response(403, null, error: 'RATING403_1');
          final result = Completer<ResponseBody>();
          pending.add(result);
          if (pending.length == 2) pair.complete();
          return result.future;
        }),
      );
      await fixture.auth.restoreSession();
      final api = FavoriteApiService(fixture.protectedClient);
      await expectLater(api.check(1), throwsA(isA<DioException>()));
      expect(storage.deletes, 0);
      denied = false;
      final all = Future.wait([
        expectLater(api.check(1), throwsA(isA<DioException>())),
        expectLater(api.check(2), throwsA(isA<DioException>())),
      ]);
      await pair.future;
      pending[0].complete(tools.response(401, null, error: 'AUTH401_2'));
      pending[1].complete(tools.response(401, null, error: 'AUTH401_4'));
      await all;
      expect(storage.deletes, 1);
      expect(fixture.auth.consumeSessionExpired(), isTrue);
      expect(fixture.auth.consumeSessionExpired(), isFalse);
    },
  );

  test('Bridge discards an old list response even after signing into the same account again', () async {
    final started = Completer<void>();
    final oldList = Completer<ResponseBody>();
    final storage = tools.MemoryStorage('old-fixture');
    final fixture = tools.Fixture(
      storage,
      tools.WorkbookAdapter((request) {
        return switch (request.path) {
          '/v8/members/me' => tools.response(200, tools.member),
          '/v8/auth/login' => tools.loggedIn('new-fixture'),
          _ => (() {
            started.complete();
            return oldList.future;
          })(),
        };
      }),
    );
    final bridge = AuthSessionBridge(fixture.auth);
    addTearDown(bridge.dispose);
    await fixture.auth.restoreSession();
    final tmdb = TmdbMovieService(
      client(
        tools.WorkbookAdapter((_) {
          fail('A stale favorite must not start a TMDB request.');
        }),
      ),
    );
    final vm = FavoritesViewModel(
      FavoriteApiService(fixture.protectedClient),
      tmdb,
      bridge.guard,
      tools.member['email']!,
    );
    addTearDown(vm.dispose);

    final refresh = vm.refresh();
    await started.future;
    await fixture.auth.logout();
    await fixture.auth.login(tools.login);
    await fixture.auth.loadMember();
    oldList.complete(tools.response(200, [favorite(9)]));
    await refresh;
    expect(vm.items, isEmpty);
  });

  testWidgets(
    'Profile opens root favorites, retries one card and refreshes on return',
    (tester) async {
      usePhoneViewport(tester);
      final storage = tools.MemoryStorage('fixture-session');
      final ids = [550, 701];
      var listFailed = true;
      var cardFailed = true;
      final api = tools.WorkbookAdapter((request) {
        switch ((request.method, request.path)) {
          case ('GET', '/v8/members/me'):
            return tools.response(200, tools.member);
          case ('GET', '/v8/favorites'):
            if (listFailed) {
              listFailed = false;
              throw offline(request);
            }
            return tools.response(200, ids.map(favorite).toList());
          case ('GET', '/v8/favorites/550'):
            return tools.response(200, {'isFavorite': ids.contains(550)});
          case ('DELETE', '/v8/favorites/550'):
            ids.remove(550);
            return tools.response(200, null);
          default:
            fail('Unexpected request: ${request.method} ${request.path}');
        }
      });
      final tmdb = tools.WorkbookAdapter((request) {
        if (request.path == '/movie/popular') return page(1, [550]);
        final id = int.parse(request.uri.pathSegments.last);
        if (id == 701 && cardFailed) {
          cardFailed = false;
          return tools.jsonBody(404, {});
        }
        return tools.jsonBody(200, {
          ...movie(id),
          'poster_path': '/fixture.jpg',
        });
      });
      await tester.pumpWidget(
        MovieLogApp(
          tokenStorage: storage,
          movieLogAdapter: api,
          tmdbAdapter: tmdb,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('내 즐겨찾기'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('즐겨찾기 목록을 불러오지 못했습니다.'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('영화 #701'), findsOneWidget);
      await tester.tap(find.text('영화 정보 다시 조회'));
      await tester.pumpAndSettle();
      expect(find.text('영화 701'), findsOneWidget);
      await tester.tap(find.text('영화 550'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('즐겨찾기 해제'));
      await tester.pumpAndSettle();
      expect(find.text('즐겨찾기를 해제했습니다.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('영화 550'), findsNothing);
      expect(find.text('영화 701'), findsOneWidget);
    },
  );

  testWidgets(
    'Debounced search has independent paging, empty and error states',
    (tester) async {
      usePhoneViewport(tester);
      final requests = <(String, int)>[];
      final api = tools.WorkbookAdapter(
        (_) => tools.response(200, tools.member),
      );
      final tmdb = tools.WorkbookAdapter((request) {
        if (request.path == '/genre/movie/list') {
          return tools.jsonBody(200, {'genres': []});
        }
        if (request.path != '/search/movie') return page(1, [99], total: 1);
        final query = request.queryParameters['query'] as String;
        final number = pageNumber(request);
        requests.add((query, number));
        if (query == 'error') throw offline(request);
        if (query == 'empty') return page(1, [], total: 0);
        return page(number, [number], total: 2);
      });
      await tester.pumpWidget(
        MovieLogApp(
          tokenStorage: tools.MemoryStorage('fixture'),
          movieLogAdapter: api,
          tmdbAdapter: tmdb,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('영화 검색'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      final input = find.byType(TextField);
      await tester.enterText(input, 'bat');
      await tester.pump(const Duration(milliseconds: 499));
      expect(requests, isEmpty);
      await tester.enterText(input, 'batman');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(requests, [('batman', 1)]);
      await tester.ensureVisible(find.text('더 보기'));
      await tester.tap(find.text('더 보기'));
      await tester.pumpAndSettle();
      expect(requests, [('batman', 1), ('batman', 2)]);
      await tester.scrollUntilVisible(
        find.text('모든 영화를 불러왔습니다.'),
        250,
        scrollable: find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('모든 영화를 불러왔습니다.'), findsOneWidget);
      await tester.enterText(input, 'empty');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
      await tester.enterText(input, 'error');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('검색 결과를 불러오지 못했습니다.'), findsOneWidget);
      await tester.enterText(input, '   ');
      await tester.pumpAndSettle();
      expect(find.text('검색어를 입력해 주세요.'), findsOneWidget);
      expect(requests, [
        ('batman', 1),
        ('batman', 2),
        ('empty', 1),
        ('error', 1),
      ]);
    },
  );

  testWidgets(
    'Discover infinite scroll retries the failed page from the footer',
    (tester) async {
      usePhoneViewport(tester);
      final requests = <int>[];
      final api = tools.WorkbookAdapter(
        (_) => tools.response(200, tools.member),
      );
      final tmdb = tools.WorkbookAdapter((request) {
        if (request.path == '/genre/movie/list') {
          return tools.jsonBody(200, {'genres': []});
        }
        if (request.path != '/discover/movie') return page(1, [99], total: 1);
        final number = pageNumber(request);
        requests.add(number);
        if (number == 2 && requests.length == 2) throw offline(request);
        return page(
          number,
          number == 1 ? List.generate(8, (i) => i + 1) : [9, 10],
          total: 2,
        );
      });
      await tester.pumpWidget(
        MovieLogApp(
          tokenStorage: tools.MemoryStorage('fixture'),
          movieLogAdapter: api,
          tmdbAdapter: tmdb,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
      expect(requests, [1]);
      expect(find.text('영화 8편'), findsOneWidget);
      expect(find.text('더 보기'), findsNothing);
      final scrollable = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('다시 시도'),
        450,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(requests, [1, 2]);
      expect(find.text('영화 8편'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(requests, [1, 2, 2]);
      expect(find.text('영화 10편'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('모든 영화를 불러왔습니다.'),
        300,
        scrollable: scrollable,
      );
      expect(find.text('더 보기'), findsNothing);
    },
  );

  testWidgets(
    'Combined rating dialog retains input on 400 and routes writes by bookmark status',
    (tester) async {
      usePhoneViewport(tester);
      var bookmarked = false;
      var saved = false;
      final writes = <({String path, Object? body})>[];
      final api = tools.WorkbookAdapter((request) {
        if (request.path == '/v8/members/me') {
          return tools.response(200, tools.member);
        }
        if (request.method == 'GET') {
          return tools.response(200, {'isFavorite': bookmarked});
        }
        writes.add((path: request.path, body: request.data));
        if (writes.length == 1) {
          return tools.response(400, null, error: 'COMMON400');
        }
        if (writes.length == 2) {
          return tools.response(409, null, error: 'FAVORITE409_1');
        }
        if (request.path == '/v8/movie-records') {
          saved = true;
          bookmarked = true;
          return tools.response(201, {
            'rating': tools.rating,
            'favorite': favorite(550),
          });
        }
        expect(saved, isTrue);
        return tools.response(201, {...tools.rating, 'movieId': 551});
      });
      final tmdb = tools.WorkbookAdapter((request) {
        if (request.path == '/movie/popular') return page(1, [550]);
        return tools.jsonBody(
          200,
          movie(int.parse(request.uri.pathSegments.last)),
        );
      });
      await tester.pumpWidget(
        MovieLogApp(
          tokenStorage: tools.MemoryStorage('fixture'),
          movieLogAdapter: api,
          tmdbAdapter: tmdb,
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(NavigationBar)));
      router.go('/movies/550');
      await tester.pumpAndSettle();

      Future<void> open() async {
        final button = find.text('평점 남기기');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> score() async {
        final input = tester.widget<MovieRatingInput>(
          find.byType(MovieRatingInput),
        );
        input.onChanged(4);
        await tester.pumpAndSettle();
      }

      await open();
      await score();
      final comment = find.byKey(const ValueKey('rating-comment'));
      await tester.enterText(comment, '후기');
      await tester.tap(find.text('즐겨찾기에도 추가'));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('후기'), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('이미 즐겨찾기에 등록된 영화입니다.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await open();
      await score();
      await tester.tap(find.text('즐겨찾기에도 추가'));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('즐겨찾기 해제'), findsOneWidget);
      expect(writes[0].body, {
        'movieId': 550,
        'score': 4,
        'comment': '후기',
        'addToFavorites': true,
      });
      expect(writes[1].body, writes[0].body);
      expect(writes[2].path, '/v8/movie-records');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      router.go('/movies/551');
      await tester.pumpAndSettle();
      await open();
      expect(find.text('즐겨찾기에도 추가'), findsNothing);
      await score();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(writes.last.path, '/v8/ratings');
      expect(writes.last.body, {'movieId': 551, 'score': 4});
    },
  );
}
