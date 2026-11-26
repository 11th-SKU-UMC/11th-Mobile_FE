import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/movie_record_models.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/load_status.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

import 'fakes.dart';

/// method·path별로 정한 JSON을 돌려주고 요청을 기록하는 가짜 HTTP 어댑터입니다.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.responses);

  /// key: 'GET /v8/favorites' → (status, body)
  final Map<String, (int, Object?)> responses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) =
        responses['${options.method} ${options.uri.path}'] ?? (200, const {});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> ok(Object? result, {String code = 'COMMON200'}) => {
  'isSuccess': true,
  'code': code,
  'message': '성공',
  'result': result,
};

Dio authDio(ScriptedAdapter adapter, String token) =>
    Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(FakeTokenStorage(token)));

const email = 'movie@umc.com';
const token = 'token-movie@umc.com';

SessionGuard startedGuard([String account = email]) =>
    SessionGuard()..startSession(account);

void main() {
  group('AuthInterceptor v8', () {
    test('즐겨찾기·영화 기록 보호 경로에만 JWT를 붙인다', () async {
      final adapter = ScriptedAdapter({});
      final dio = authDio(adapter, 'abc');

      await dio.get('/v8/favorites');
      await dio.post('/v8/favorites');
      await dio.get('/v8/favorites/550');
      await dio.delete('/v8/favorites/550');
      await dio.post('/v8/movie-records');
      await dio.get('/v8/members/me');
      // 아래는 보호 요청이 아닙니다.
      await dio.put('/v8/favorites/550');
      await dio.get('/v8/favorites/0');
      await dio.get('/v8/movie-records');
      await dio.get('/v7/members/me');
      await dio.post('/v8/auth/login');
      await dio.get('https://api.themoviedb.org/v8/favorites');

      expect(adapter.requests.map((r) => r.headers['Authorization']), [
        'Bearer abc',
        'Bearer abc',
        'Bearer abc',
        'Bearer abc',
        'Bearer abc',
        'Bearer abc',
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
    });
  });

  group('FavoriteApiService', () {
    test('목록·여부·등록을 CommonResponse로 파싱하고, 해제는 200 + null을 성공으로 본다', () async {
      final adapter = ScriptedAdapter({
        'GET /v8/favorites': (
          200,
          ok([
            {
              'favoriteId': 3,
              'movieId': 550,
              'createdAt': '2026-09-06T12:14:03.000Z',
            },
          ]),
        ),
        'GET /v8/favorites/550': (200, ok({'isFavorite': true})),
        'POST /v8/favorites': (
          201,
          ok({
            'favoriteId': 4,
            'movieId': 13,
            'createdAt': '2026-09-06T12:14:03.000Z',
          }, code: 'COMMON201'),
        ),
        'DELETE /v8/favorites/550': (200, ok(null)),
      });
      final service = FavoriteApiService(authDio(adapter, token));

      final list = await service.fetchMyFavorites();
      expect(list.single.movieId, 550);
      expect(list.single.favoriteId, 3);

      // 여부 응답에는 movieId가 없어서 요청한 값을 함께 넘깁니다.
      final check = await service.checkFavorite(movieId: 550);
      expect(check.movieId, 550);
      expect(check.isFavorite, isTrue);

      final added = await service.addFavorite(movieId: 13);
      expect(added.favoriteId, 4);
      expect(adapter.requests[2].data, {'movieId': 13});

      await service.deleteFavorite(movieId: 550);
      expect(adapter.requests.last.method, 'DELETE');
    });

    test('즐겨찾기가 없으면 빈 배열이다', () async {
      final adapter = ScriptedAdapter({'GET /v8/favorites': (200, ok([]))});
      final service = FavoriteApiService(authDio(adapter, token));
      expect(await service.fetchMyFavorites(), isEmpty);
    });

    test('FAVORITE409_1은 code를 가진 DioException으로 던진다', () async {
      final adapter = ScriptedAdapter({
        'POST /v8/favorites': (
          409,
          {
            'isSuccess': false,
            'code': 'FAVORITE409_1',
            'message': '이미 이 영화를 즐겨찾기하셨습니다.',
            'result': null,
          },
        ),
      });
      final service = FavoriteApiService(authDio(adapter, token));
      await expectLater(
        service.addFavorite(movieId: 550),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['code'],
            'code',
            'FAVORITE409_1',
          ),
        ),
      );
    });

    test('영화 기록 저장은 addToFavorites를 항상 보내고 favorite null을 허용한다', () async {
      final adapter = ScriptedAdapter({
        'POST /v8/movie-records': (
          201,
          ok({
            'rating': {
              'ratingId': 9,
              'movieId': 550,
              'score': 4,
              'comment': null,
              'createdAt': '2026-09-06T12:14:03.000Z',
            },
            'favorite': null,
          }, code: 'COMMON201'),
        ),
      });
      final service = MovieRecordApiService(authDio(adapter, token));

      final result = await service.createMovieRecord(
        const CreateMovieRecordRequest(
          movieId: 550,
          score: 4,
          addToFavorites: false,
        ),
      );

      expect(result.rating.ratingId, 9);
      expect(result.favorite, isNull);
      expect(adapter.requests.single.data, {
        'movieId': 550,
        'score': 4,
        'addToFavorites': false,
      });
      expect(adapter.requests.single.headers['Authorization'], 'Bearer $token');
    });
  });

  group('mapBounded', () {
    test('결과 순서를 유지하고 동시 요청을 제한한다', () async {
      var active = 0;
      var maxActive = 0;
      final result = await mapBounded(List.generate(12, (i) => i), 5, (
        value,
      ) async {
        active++;
        if (active > maxActive) maxActive = active;
        await Future<void>.delayed(Duration(milliseconds: 12 - value));
        active--;
        return value * 10;
      });

      expect(result, List.generate(12, (i) => i * 10));
      expect(maxActive, 5);
    });
  });

  group('SessionGuard / AuthSessionBridge', () {
    test('같은 이메일로 다시 로그인해도 새 세션이며, 닉네임 변경만으로는 바뀌지 않는다', () {
      final signals = ChangeNotifier();
      var version = 1;
      String? verified = email;
      final bridge = AuthSessionBridge(
        authSignals: signals,
        sessionVersion: () => version,
        verifiedEmail: () => verified,
      );
      final first = bridge.guard.generation;
      expect(bridge.guard.accountId, email);

      // 닉네임 수정: version·email 그대로 → 세션 유지
      signals.notifyListeners();
      expect(bridge.guard.generation, first);
      expect(bridge.guard.isCurrent(first, email), isTrue);

      // 로그아웃 → 같은 이메일로 다시 로그인
      version = 2;
      verified = null;
      signals.notifyListeners();
      expect(bridge.guard.accountId, isNull);
      version = 3;
      verified = email;
      signals.notifyListeners();
      expect(bridge.guard.accountId, email);
      expect(bridge.guard.isCurrent(first, email), isFalse);

      bridge.dispose();
      signals.dispose();
    });
  });

  group('FavoriteDetailViewModel', () {
    late FakeTokenStorage storage;
    late FakeFavoriteApiService api;
    late SessionGuard guard;
    var expiredCalls = 0;

    FavoriteDetailViewModel create({int movieId = 550}) =>
        FavoriteDetailViewModel(
          movieId: movieId,
          favoriteApi: api,
          sessionGuard: guard,
          accountId: email,
          onSessionExpired: () async => expiredCalls++,
        );

    setUp(() {
      storage = FakeTokenStorage(token);
      api = FakeFavoriteApiService(storage);
      guard = startedGuard();
      expiredCalls = 0;
    });

    test('서버 여부를 반영하고, 성공을 확인한 뒤에만 북마크를 바꾼다', () async {
      final vm = create();
      await vm.load();
      expect(vm.hasLoadedStatus, isTrue);
      expect(vm.isFavorite, isFalse);

      api.addGate = Completer<void>();
      final saving = vm.toggle();
      expect(vm.isSaving, isTrue);
      expect(vm.isFavorite, isFalse); // optimistic update를 하지 않습니다.
      await vm.toggle(); // 요청 중 중복 탭은 무시합니다.
      api.addGate!.complete();
      await saving;

      expect(vm.isFavorite, isTrue);
      expect(api.addCalls, [550]);

      await vm.toggle();
      expect(vm.isFavorite, isFalse);
      expect(api.deleteCalls, [550]);
    });

    test('실패하면 이전 상태를 유지하고 안내한다', () async {
      final vm = create();
      await vm.load();
      api.addError = dioError(500, '/v8/favorites');

      await vm.toggle();

      expect(vm.isFavorite, isFalse);
      expect(vm.errorMessage, '즐겨찾기 등록에 실패했습니다.');
      expect(expiredCalls, 0);
    });

    test(
      'FAVORITE409_1·FAVORITE404_1은 POST·DELETE를 반복하지 않고 현재 여부로 맞춘다',
      () async {
        final vm = create();
        await vm.load();
        // 다른 기기에서 이미 등록됨 → 화면은 false인데 서버는 true
        api.seed(token, [550]);
        await vm.toggle();
        expect(api.addCalls, [550]);
        expect(vm.isFavorite, isTrue);
        expect(vm.errorMessage, isNull);
        expect(api.checkCalls, [550, 550]);

        // 다른 기기에서 이미 해제됨 → 404 → 다시 조회해 false
        await api.deleteFavorite(movieId: 550);
        api.deleteCalls.clear();
        await vm.toggle();
        expect(api.deleteCalls, [550]);
        expect(vm.isFavorite, isFalse);
      },
    );

    test('첫 여부 조회가 실패하면 토글할 수 없고 다시 확인할 수 있다', () async {
      final vm = create();
      api.checkError = dioError(500, '/v8/favorites/550');
      await vm.load();
      expect(vm.hasLoadedStatus, isFalse);
      expect(vm.errorMessage, '즐겨찾기 여부를 확인하지 못했습니다.');

      await vm.toggle();
      expect(api.addCalls, isEmpty);

      api.checkError = null;
      await vm.load();
      expect(vm.hasLoadedStatus, isTrue);
    });

    test('현재 세션의 401은 한 번 만료 처리하고, 403은 로그아웃하지 않는다', () async {
      final vm = create();
      await vm.load();
      api.addError = dioError(403, '/v8/favorites', code: 'COMMON403');
      await vm.toggle();
      expect(expiredCalls, 0);

      api.addError = expiredError('/v8/favorites');
      await vm.toggle();
      expect(expiredCalls, 1);
      expect(vm.sessionExpired, isTrue);
    });

    test('세션이 바뀐 뒤 늦게 도착한 응답과 401은 무시한다', () async {
      final vm = create();
      await vm.load();
      api.addGate = Completer<void>();
      api.addError = expiredError('/v8/favorites');
      final saving = vm.toggle();

      // 응답 전에 로그아웃 → 다른 계정 로그인
      guard
        ..invalidate()
        ..startSession('other@umc.com');
      api.addGate!.complete();
      await saving;

      expect(expiredCalls, 0); // 이전 계정의 401이 새 계정을 로그아웃시키지 않습니다.
      expect(vm.isSaving, isTrue); // 이 ViewModel은 곧 버려지므로 더 이상 갱신하지 않습니다.
    });

    test('잘못된 movieId로는 보호 요청을 보내지 않는다', () async {
      final vm = create(movieId: 0);
      await vm.load();
      expect(api.checkCalls, isEmpty);
    });

    test('dispose 뒤 도착한 응답은 notifyListeners를 호출하지 않는다', () async {
      final vm = create();
      api.checkGate = Completer<void>();
      final loading = vm.load();
      vm.dispose();
      api.checkGate!.complete();
      await loading; // 예외 없이 끝나야 합니다.
      expect(vm.isDisposed, isTrue);
    });
  });

  group('FavoritesViewModel', () {
    late FakeTokenStorage storage;
    late FakeFavoriteApiService api;
    late FakeTmdbMovieService tmdb;
    late SessionGuard guard;
    var expiredCalls = 0;

    FavoritesViewModel create({String account = email}) => FavoritesViewModel(
      favoriteApi: api,
      tmdbApi: tmdb,
      sessionGuard: guard,
      accountId: account,
      onSessionExpired: () async => expiredCalls++,
    );

    setUp(() {
      storage = FakeTokenStorage(token);
      api = FakeFavoriteApiService(storage);
      tmdb = FakeTmdbMovieService();
      guard = startedGuard();
      expiredCalls = 0;
    });

    test('movieId로 TMDB 정보를 합치고, 한 건 실패는 그 카드만 placeholder가 된다', () async {
      api.seed(token, [1, 2, 3]);
      tmdb.failingDetailIds.add(2);
      final vm = create();
      await vm.refresh();

      expect(vm.phase, LoadPhase.ready);
      expect(vm.items.map((i) => i.movie?.title), [
        'TMDB 영화 1',
        null,
        'TMDB 영화 3',
      ]);
      expect(vm.items[1].errorMessage, '영화 정보를 불러오지 못했습니다.');

      // 그 카드만 다시 조회합니다.
      tmdb.failingDetailIds.clear();
      tmdb.detailCalls.clear();
      await vm.retryMovie(vm.items[1].favorite.favoriteId);
      expect(tmdb.detailCalls, [2]);
      expect(vm.items[1].movie?.title, 'TMDB 영화 2');
    });

    test('TMDB 보충 요청은 한 번에 최대 5개만 보낸다', () async {
      api.seed(token, List.generate(12, (i) => i + 1));
      tmdb.gates['detail'] = Completer<void>();
      final vm = create();
      final loading = vm.refresh();
      await pumpEventQueue();
      expect(tmdb.activeDetailCalls, 5);

      tmdb.gates['detail']!.complete();
      await loading;
      expect(tmdb.maxActiveDetailCalls, 5);
      expect(vm.items.length, 12);
    });

    test('빈 목록과 조회 오류를 구분한다', () async {
      final vm = create();
      await vm.refresh();
      expect(vm.phase, LoadPhase.empty);

      api.listError = dioError(500, '/v8/favorites');
      final failing = create();
      await failing.refresh();
      expect(failing.phase, LoadPhase.error);
      expect(failing.errorMessage, '내 즐겨찾기 목록을 불러오지 못했습니다.');
      expect(expiredCalls, 0);
    });

    test('다시 조회는 기존 목록을 유지하고, 해제된 영화를 목록에서 뺀다', () async {
      api.seed(token, [1, 2]);
      final vm = create();
      await vm.refresh();

      await api.deleteFavorite(movieId: 1);
      tmdb.detailCalls.clear();
      api.listGate = Completer<void>();
      final refreshing = vm.refresh();
      expect(vm.isRefreshing, isTrue);
      expect(vm.items.length, 2); // 기존 카드를 지우지 않습니다.
      api.listGate!.complete();
      await refreshing;

      expect(vm.items.map((i) => i.favorite.movieId), [2]);
      expect(tmdb.detailCalls, isEmpty); // 이미 받은 영화 정보는 Map 캐시로 재사용합니다.
    });

    test('만료 토큰이면 세션을 정리하고, 계정이 바뀐 뒤의 응답은 버린다', () async {
      api.listError = expiredError('/v8/favorites');
      final vm = create();
      await vm.refresh();
      expect(expiredCalls, 1);

      api.listError = null;
      api.seed(token, [1]);
      final stale = create();
      api.listGate = Completer<void>();
      final loading = stale.refresh();
      guard
        ..invalidate()
        ..startSession('other@umc.com');
      api.listGate!.complete();
      await loading;
      expect(stale.items, isEmpty);
      expect(stale.phase, LoadPhase.loading);
    });
  });

  group('PagedMoviesViewModel', () {
    test('더 보기는 중복 movieId를 빼고 append하고 nextPage를 올린다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(tmdbApi: service);
      await vm.loadInitial();
      expect(vm.movies.length, 20);
      expect(vm.nextPage, 2);

      await vm.loadNextPage();
      // 2 page의 앞 5개는 1 page와 겹칩니다.
      expect(vm.movies.length, 35);
      expect(vm.movies.map((m) => m.id).toSet().length, 35);
      expect(vm.nextPage, 3);
    });

    test('다음 page 실패는 목록과 nextPage를 유지하고 같은 page를 다시 요청한다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(tmdbApi: service);
      await vm.loadInitial();
      service.failDiscoverPages.add(2);

      await vm.loadNextPage();
      expect(vm.movies.length, 20);
      expect(vm.nextPage, 2);
      expect(vm.loadMoreError, isNotNull);
      expect(vm.phase, LoadPhase.ready);

      service.failDiscoverPages.clear();
      await vm.loadNextPage();
      expect(service.discoverCalls.map((c) => c.page), [1, 2, 2]);
      expect(vm.loadMoreError, isNull);
      expect(vm.nextPage, 3);
    });

    test('다음 page 요청 중에는 중복 요청하지 않는다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(tmdbApi: service);
      await vm.loadInitial();
      service.gates['discover::2'] = Completer<void>();

      final first = vm.loadNextPage();
      expect(vm.isLoadingMore, isTrue);
      await vm.loadNextPage();
      service.gates['discover::2']!.complete();
      await first;

      expect(service.discoverCalls.where((c) => c.page == 2).length, 1);
    });

    test('마지막 page에서는 hasMore가 false이고, TMDB 최대 500 page를 넘지 않는다', () async {
      final service = FakeTmdbMovieService(totalPages: 2);
      final vm = PagedMoviesViewModel(tmdbApi: service);
      await vm.loadInitial();
      await vm.loadNextPage();
      expect(vm.hasMore, isFalse);
      await vm.loadNextPage();
      expect(service.discoverCalls.length, 2);

      service.totalPages = 900;
      await vm.loadInitial();
      expect(vm.totalPages, 500);
    });

    test('장르를 바꾸면 이전 장르의 늦은 응답이 새 목록에 섞이지 않는다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(tmdbApi: service);
      service.gates['discover:28:1'] = Completer<void>();

      final slow = vm.loadInitial(genreIds: [28]);
      await vm.loadInitial(genreIds: [18]);
      service.gates['discover:28:1']!.complete();
      await slow;

      expect(vm.condition.genreIds, [18]);
      expect(vm.movies.every((m) => m.id > 18000 && m.id < 19000), isTrue);
    });

    test('다음 page 요청 중 조건이 바뀌면 그 응답·로딩 상태를 버린다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(tmdbApi: service);
      await vm.loadInitial();
      service.gates['discover::2'] = Completer<void>();
      final more = vm.loadNextPage();

      await vm.loadInitial(genreIds: [28]);
      expect(vm.isLoadingMore, isFalse);
      service.gates['discover::2']!.complete();
      await more;

      expect(vm.isLoadingMore, isFalse);
      expect(vm.nextPage, 2);
      expect(vm.movies.every((m) => m.id > 28000), isTrue);
    });

    test('검색: 빈 검색어는 요청하지 않고, 결과 없음과 오류를 구분한다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(
        tmdbApi: service,
        mode: PagedMoviesMode.search,
      );
      await vm.loadInitial(query: '   ');
      expect(vm.phase, LoadPhase.idle);
      expect(service.searchCalls, isEmpty);

      await vm.loadInitial(query: '없는영화');
      expect(vm.phase, LoadPhase.empty);

      await vm.loadInitial(query: ' 아이언맨 ');
      expect(service.searchCalls.last, (page: 1, query: '아이언맨'));
      expect(vm.phase, LoadPhase.ready);
      await vm.loadNextPage();
      expect(vm.movies.length, 8);
      expect(vm.hasMore, isFalse);

      service.failSearch = true;
      await vm.loadInitial(query: '실패');
      expect(vm.phase, LoadPhase.error);
      expect(vm.errorMessage, '검색 결과를 불러오지 못했습니다.');
    });

    test('검색어를 빠르게 바꾸면 이전 검색어의 응답을 무시한다', () async {
      final service = FakeTmdbMovieService();
      final vm = PagedMoviesViewModel(
        tmdbApi: service,
        mode: PagedMoviesMode.search,
      );
      service.gates['search:어벤:1'] = Completer<void>();
      final slow = vm.loadInitial(query: '어벤');
      await vm.loadInitial(query: '어벤져스');
      service.gates['search:어벤:1']!.complete();
      await slow;

      expect(vm.movies.every((m) => m.title.startsWith('어벤져스')), isTrue);
    });
  });

  group('MovieDetailViewModel 영화 기록(Challenge)', () {
    Future<
      (MovieDetailViewModel, FakeMovieRecordApiService, MyRatingsViewModel)
    >
    create({FakeMovieRecordApiService? records}) async {
      final auth = await signedInAuth();
      final ratingService = FakeRatingApiService();
      final myRatings = MyRatingsViewModel(ratingService, auth);
      final recordApi = records ?? FakeMovieRecordApiService();
      final vm = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratingService,
        auth,
        myRatings,
        7,
        initialMovie: movieDto(7),
        recordService: recordApi,
      );
      await vm.load();
      return (vm, recordApi, myRatings);
    }

    test('addToFavorites를 주면 movie-records로 한 번에 저장한다', () async {
      final (vm, records, myRatings) = await create();
      await vm.createRating(score: 5, comment: '최고', addToFavorites: true);

      expect(vm.submitStatus, SubmitStatus.success);
      expect(records.calls.single.toJson(), {
        'movieId': 7,
        'score': 5,
        'comment': '최고',
        'addToFavorites': true,
      });
      expect(myRatings.findByMovieId(7)?.rating.ratingId, 300);
      expect(vm.needsFavoriteSync, isTrue);
    });

    test('409·MEMBER404_1은 Dialog를 닫고, COMMON400·네트워크 실패는 열어 둔다', () async {
      final records = FakeMovieRecordApiService();
      final (vm, _, _) = await create(records: records);

      records.error = dioError(
        409,
        '/v8/movie-records',
        code: 'RATING409_1',
        message: '이미 이 영화에 평점을 남기셨습니다.',
      );
      await vm.createRating(score: 3, addToFavorites: true);
      expect(vm.shouldCloseDialog, isTrue);
      expect(vm.submitMessage, '이미 이 영화에 평점을 남기셨습니다.');

      records.error = dioError(409, '/v8/movie-records', code: 'FAVORITE409_1');
      await vm.createRating(score: 3, addToFavorites: true);
      expect(vm.shouldCloseDialog, isTrue);
      expect(vm.needsFavoriteSync, isTrue);

      records.error = dioError(
        400,
        '/v8/movie-records',
        code: 'COMMON400',
        message: '별점은 5점 이하여야 합니다.',
      );
      await vm.createRating(score: 3, addToFavorites: false);
      expect(vm.shouldCloseDialog, isFalse);
      expect(vm.submitMessage, '별점은 5점 이하여야 합니다.');

      records.error = dioError(500, '/v8/movie-records');
      await vm.createRating(score: 3, addToFavorites: false);
      expect(vm.shouldCloseDialog, isFalse);
      expect(vm.status, LoadStatus.success);
    });
  });
}
