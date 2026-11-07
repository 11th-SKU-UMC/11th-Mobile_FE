import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/core/network/tmdb_logging_interceptor.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie_rating.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/screens/movies_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

typedef _Responder = FutureOr<Object> Function(RequestOptions);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final _Responder respond;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return ResponseBody.fromString(
      jsonEncode(await respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _movie(int id) => {
  'id': id,
  'title': '영화$id',
  'poster_path': null,
  'overview': '',
  'genre_ids': [28],
  'vote_average': 8,
  'popularity': 10,
};

Map<String, dynamic> _page(List<int> ids, {int page = 1, int totalPages = 1}) =>
    {
      'page': page,
      'results': ids.map(_movie).toList(),
      'total_pages': totalPages,
      'total_results': ids.length,
    };

const _genres = {
  'genres': [
    {'id': 28, 'name': '액션'},
    {'id': 16, 'name': '애니메이션'},
  ],
};

(Dio, _Adapter, TmdbMovieService) _service(_Responder respond) {
  final adapter = _Adapter(respond);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
    ..httpClientAdapter = adapter;
  addTearDown(() => dio.close(force: true));
  return (dio, adapter, TmdbMovieService(dio));
}

void main() {
  test('DTO handles missing fields, numeric conversion, and detail genres', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 550,
      'genres': [
        {'id': 18, 'name': '드라마'},
      ],
      'vote_average': 8,
    });
    expect(movie.title, '제목 없음');
    expect(movie.posterPath, isNull);
    expect(movie.releaseDate, isNull);
    expect(movie.overview, '');
    expect(movie.genreIds, [18]);
    expect(movie.genres.single.name, '드라마');
    expect(movie.voteAverage, 8.0);
  });

  test(
    'Discover omits all-genres condition and joins multiple IDs with OR',
    () async {
      final (_, adapter, service) = _service((_) => _page([]));
      await service.discoverMovies(page: 1);
      await service.discoverMovies(page: 1, genreIds: []);
      await service.discoverMovies(page: 2, genreIds: [28]);
      await service.discoverMovies(page: 1, genreIds: [28, 16]);
      expect(adapter.calls[0].queryParameters, isNot(contains('with_genres')));
      expect(adapter.calls[1].queryParameters, isNot(contains('with_genres')));
      expect(adapter.calls[2].queryParameters['with_genres'], '28');
      expect(adapter.calls[3].queryParameters['with_genres'], '28|16');
    },
  );

  test(
    'Popular keeps fewer than five films and recovers after a failure',
    () async {
      var fail = true;
      final (_, _, service) = _service((options) {
        if (fail) throw DioException(requestOptions: options);
        return _page([550, 551, 552]);
      });
      final vm = MovieHomeViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadPopular();
      expect(vm.status, MovieHomeLoadStatus.error);
      fail = false;
      await vm.loadPopular();
      expect(vm.status, MovieHomeLoadStatus.success);
      expect(vm.popularMovies.map((movie) => movie.id), [550, 551, 552]);
      expect(vm.message, isNull);
    },
  );

  test(
    'Discover collects 30 unique IDs without assuming a page size',
    () async {
      final (_, adapter, service) = _service((options) {
        if (options.path == '/genre/movie/list') return _genres;
        final page = options.queryParameters['page'] as int;
        final ids = switch (page) {
          1 => List.generate(12, (index) => index + 1),
          2 => List.generate(12, (index) => index + 10),
          _ => List.generate(20, (index) => index + 20),
        };
        return _page(ids, page: page, totalPages: 10);
      });
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      expect(vm.status, MovieListLoadStatus.success);
      expect(
        vm.movies.map((movie) => movie.id),
        List.generate(30, (index) => index + 1),
      );
      expect(
        adapter.calls.where((call) => call.path == '/discover/movie').length,
        3,
      );
    },
  );

  test(
    'Last or empty pages stop loading and fewer than 30 films are valid',
    () async {
      final (_, adapter, service) = _service((options) {
        if (options.path == '/genre/movie/list') return _genres;
        final page = options.queryParameters['page'] as int;
        return _page(page == 1 ? [7, 8] : [], page: page, totalPages: 100);
      });
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      expect(vm.movies.length, 2);
      expect(vm.status, MovieListLoadStatus.success);
      expect(adapter.calls.length, 3);
    },
  );

  test(
    'Genre selection restarts at page one; clearing omits the filter',
    () async {
      final (_, adapter, service) = _service((options) {
        if (options.path == '/genre/movie/list') return _genres;
        return _page([1001]);
      });
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      await vm.selectGenres([28, 16, 28]);
      expect(vm.selectedGenreIds, [16, 28]);
      expect(adapter.calls.last.queryParameters['page'], 1);
      expect(adapter.calls.last.queryParameters['with_genres'], '16|28');
      await vm.selectGenres([]);
      expect(vm.selectedGenreIds, isNull);
      expect(
        adapter.calls.last.queryParameters,
        isNot(contains('with_genres')),
      );
    },
  );

  test(
    'Refresh keeps the last successful list and retries the same filter',
    () async {
      var fail = false;
      final (_, adapter, service) = _service((options) {
        if (options.path == '/genre/movie/list') return _genres;
        if (fail) throw DioException(requestOptions: options);
        return _page([969681]);
      });
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      await vm.selectGenres([28]);
      fail = true;
      final refreshing = vm.refresh();
      expect(vm.isLoading, isTrue);
      expect(vm.showMovies, isTrue);
      expect(vm.movies.single.id, 969681);
      await refreshing;
      expect(vm.status, MovieListLoadStatus.error);
      expect(vm.showingPreviousResults, isTrue);
      expect(vm.movies.single.id, 969681);
      fail = false;
      await vm.retry();
      expect(vm.status, MovieListLoadStatus.success);
      expect(adapter.calls.last.queryParameters['with_genres'], '28');
      expect(adapter.calls.last.queryParameters['page'], 1);
    },
  );

  test(
    'Busy requests block genre changes and disposal ignores late responses',
    () async {
      final response = Completer<Map<String, dynamic>>();
      final started = Completer<void>();
      final (_, adapter, service) = _service((options) {
        if (options.path == '/genre/movie/list') return _genres;
        started.complete();
        return response.future;
      });
      final vm = MovieListViewModel(service);
      final loading = vm.loadInitial();
      await started.future;
      await vm.selectGenres([28]);
      expect(vm.selectedGenreIds, isNull);
      vm.dispose();
      response.complete(_page([1], totalPages: 10));
      await loading;
      expect(vm.movies, isEmpty);
      expect(
        adapter.calls.where((call) => call.path == '/discover/movie').length,
        1,
      );
    },
  );

  test('No results become Empty and initial failure can be retried', () async {
    var fail = true;
    final (_, _, service) = _service((options) {
      if (fail) throw DioException(requestOptions: options);
      if (options.path == '/genre/movie/list') return _genres;
      return _page([]);
    });
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(vm.status, MovieListLoadStatus.error);
    fail = false;
    await vm.retry();
    expect(vm.status, MovieListLoadStatus.empty);
    expect(vm.genres.length, 2);
  });

  test(
    'Logs mask authorization while the real request header stays intact',
    () async {
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          logs.add(message ?? '');
      addTearDown(() => debugPrint = previousDebugPrint);
      final (dio, adapter, service) = _service((options) {
        throw DioException(requestOptions: options, message: 'offline');
      });
      dio.options.headers['authorization'] = 'Bearer test-secret';
      dio.interceptors.add(TmdbLoggingInterceptor());
      await expectLater(service.fetchPopular(), throwsA(isA<DioException>()));
      expect(logs.join(), contains('Bearer ***'));
      expect(logs.join(), isNot(contains('test-secret')));
      expect(logs.join(), contains('[TMDB 오류]'));
      expect(
        adapter.calls.single.headers['authorization'],
        'Bearer test-secret',
      );
    },
  );

  test(
    'Detail reload uses the URL ID and ratings keep the same movie ID',
    () async {
      final (_, adapter, service) = _service(
        (_) => {
          ..._movie(969681),
          'genres': [
            {'id': 28, 'name': '액션'},
          ],
        },
      );
      final vm = MovieDetailViewModel(service, movieId: 969681);
      addTearDown(vm.dispose);
      await vm.loadMovie();
      expect(adapter.calls.single.path, '/movie/969681');
      expect(vm.movie!.id, 969681);
      vm.setRating(const MovieRating(movieId: 0, score: 4));
      expect(vm.myRating, isNull);
      vm.setRating(const MovieRating(movieId: 969681, score: 4.5));
      expect(vm.myRating!.movieId, 969681);
      expect(vm.myRating!.score, 4.5);
    },
  );

  testWidgets('Home renders fewer than five films and missing posters safely', (
    tester,
  ) async {
    final (_, _, service) = _service((_) => _page([550, 551, 552]));
    final router = GoRouter(
      navigatorKey: AppRouter.rootNavigatorKey,
      initialLocation: '/home',
      routes: AppRouter.router.configuration.routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Provider<TmdbMovieService>.value(
        value: service,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('영화550'), findsWidgets);
    expect(find.byType(TmdbPosterImage), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Real movie ID reaches the detail screen and rating dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (_, _, service) = _service((options) {
      if (options.path == '/genre/movie/list') return _genres;
      if (options.path == '/discover/movie') return _page([969681]);
      return {..._movie(969681), 'genres': _genres['genres']};
    });
    final router = GoRouter(
      navigatorKey: AppRouter.rootNavigatorKey,
      initialLocation: '/movies',
      routes: AppRouter.router.configuration.routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Provider<TmdbMovieService>.value(
        value: service,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);
    final vm = tester
        .element(find.byType(MovieDetailScreen))
        .read<MovieDetailViewModel>();
    expect(vm.movieId, 969681);
    await tester.scrollUntilVisible(
      find.text('평점 남기기'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(MovieDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RatingDialog>(find.byType(RatingDialog)).movieId,
      969681,
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(vm.myRating!.movieId, 969681);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Refresh failure preserves results and the dialog retries successfully',
    (tester) async {
      var fail = false;
      final (_, _, service) = _service((options) {
        if (options.path == '/genre/movie/list') return _genres;
        if (fail) throw DioException(requestOptions: options);
        return _page([969681]);
      });
      final router = GoRouter(
        navigatorKey: AppRouter.rootNavigatorKey,
        initialLocation: '/movies',
        routes: AppRouter.router.configuration.routes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        Provider<TmdbMovieService>.value(
          value: service,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final vm = tester
          .element(find.byType(MoviesScreen))
          .read<MovieListViewModel>();
      final selecting = vm.selectGenres([28]);
      await tester.pumpAndSettle();
      await selecting;
      fail = true;
      final refreshing = vm.refresh();
      await tester.pumpAndSettle();
      await refreshing;
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('영화969681'), findsOneWidget);
      fail = false;
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('재시도'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(vm.status, MovieListLoadStatus.success);
      expect(vm.selectedGenreIds, [28]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Initial error retries to Empty and keeps all-genres available', (
    tester,
  ) async {
    var fail = true;
    final (_, _, service) = _service((options) {
      if (fail) throw DioException(requestOptions: options);
      if (options.path == '/genre/movie/list') return _genres;
      return _page([]);
    });
    final router = GoRouter(
      navigatorKey: AppRouter.rootNavigatorKey,
      initialLocation: '/movies',
      routes: AppRouter.router.configuration.routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Provider<TmdbMovieService>.value(
        value: service,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loading disables chips and multi-select sends OR conditions', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    var first = true;
    final (_, adapter, service) = _service((options) {
      if (options.path == '/genre/movie/list') return _genres;
      if (first) {
        first = false;
        return pending.future;
      }
      return _page([969681]);
    });
    final router = GoRouter(
      navigatorKey: AppRouter.rootNavigatorKey,
      initialLocation: '/movies',
      routes: AppRouter.router.configuration.routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Provider<TmdbMovieService>.value(
        value: service,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.onSelected, isNull);
    }
    pending.complete(_page([969681]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장르 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '액션'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CheckboxListTile, '애니메이션'));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(adapter.calls.last.queryParameters['with_genres'], '16|28');
    final beforeRefresh = adapter.calls.length;
    await tester.drag(find.byType(GridView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(adapter.calls.length, greaterThan(beforeRefresh));
    expect(adapter.calls.last.queryParameters['with_genres'], '16|28');
    expect(adapter.calls.last.queryParameters['page'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A failed network poster renders the placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TmdbPosterImage(
            posterPath: '/missing-poster.jpg',
            width: 140,
            height: 195,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('v5 models parse a raw array and a nullable comment', () async {
    final (dio, adapter, _) = _service((_) => [_rating(1)]);
    final ratings = await RatingApiService(dio).fetchMyRatings(1);
    expect(adapter.calls.single.path, '/v5/members/1/ratings');
    expect(ratings.single.movieId, 550);
    expect(ratings.single.comment, isNull);
    expect(ratings.single.createdAt.isUtc, isTrue);
    expect(RatingDto.fromJson(_rating(2, comment: '좋아요')).comment, '좋아요');
  });

  test('Checks trim and encode values without a response wrapper', () async {
    final (dio, adapter, _) = _service((_) => {'available': true});
    final service = MemberCheckService(dio);
    expect(await service.checkNickname(' 무비 러버/영화 '), isTrue);
    expect(
      adapter.calls.first.path,
      '/v5/members/nickname/${Uri.encodeComponent('무비 러버/영화')}',
    );
    expect(await service.checkEmail(' movie+test@example.com '), isTrue);
    expect(
      adapter.calls.last.path,
      '/v5/members/email/${Uri.encodeComponent('movie+test@example.com')}',
    );
  });

  test(
    'Nickname and email requests stay independent and remember duplicates',
    () async {
      final pendingNickname = Completer<Object>();
      final (dio, adapter, _) = _service((options) {
        if (options.path.contains('/nickname/')) return pendingNickname.future;
        return {'available': false};
      });
      final vm = SignUpViewModel(MemberCheckService(dio));
      addTearDown(vm.dispose);
      vm.onNicknameChanged('중복닉네임');
      final checkingNickname = vm.checkNickname('중복닉네임');
      expect(vm.nicknameCheckStatus, CheckStatus.checking);
      expect(vm.canCheckNickname, isFalse);
      vm.onEmailChanged('taken@example.com');
      await vm.checkEmail('taken@example.com');
      expect(vm.emailCheckStatus, CheckStatus.duplicated);
      expect(vm.canCheckEmail, isFalse);
      pendingNickname.complete({'available': false});
      await checkingNickname;
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);

      final calls = adapter.calls.length;
      vm.onNicknameChanged('다른닉네임');
      vm.onEmailChanged('other@example.com');
      expect(vm.nicknameErrorText, isNull);
      expect(vm.emailErrorText, isNull);
      expect(vm.canCheckNickname, isTrue);
      expect(vm.canCheckEmail, isTrue);
      vm.onNicknameChanged(' 중복닉네임 ');
      vm.onEmailChanged(' taken@example.com ');
      await vm.checkNickname('중복닉네임');
      await vm.checkEmail('taken@example.com');
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      expect(vm.emailCheckStatus, CheckStatus.duplicated);
      expect(adapter.calls.length, calls);
    },
  );

  test(
    'Check failures can retry and input edits invalidate available results',
    () async {
      var fail = true;
      final (dio, _, _) = _service((options) {
        if (fail) throw DioException(requestOptions: options);
        return {'available': true};
      });
      final vm = SignUpViewModel(MemberCheckService(dio));
      addTearDown(vm.dispose);
      vm.onNicknameChanged('사용가능');
      vm.onEmailChanged('available@example.com');
      await Future.wait([
        vm.checkNickname('사용가능'),
        vm.checkEmail('available@example.com'),
      ]);
      expect(vm.nicknameCheckStatus, CheckStatus.error);
      expect(vm.emailCheckStatus, CheckStatus.error);
      expect(vm.nicknameErrorText, contains('실패'));
      expect(vm.emailErrorText, contains('실패'));
      expect(vm.canCheckNickname, isTrue);
      expect(vm.canCheckEmail, isTrue);
      fail = false;
      await Future.wait([
        vm.checkNickname('사용가능'),
        vm.checkEmail('available@example.com'),
      ]);
      expect(vm.nicknameCheckStatus, CheckStatus.available);
      expect(vm.emailCheckStatus, CheckStatus.available);
      vm.onNicknameChanged('새닉네임');
      vm.onEmailChanged('new@example.com');
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      expect(vm.emailCheckStatus, CheckStatus.idle);
    },
  );

  test(
    'Late check results cannot overwrite newer input or a disposed screen',
    () async {
      final pending = Completer<Object>();
      final (dio, _, _) = _service((_) => pending.future);
      final vm = SignUpViewModel(MemberCheckService(dio));
      vm.onNicknameChanged('이전닉네임');
      vm.onEmailChanged('old@example.com');
      final nicknameRequest = vm.checkNickname('이전닉네임');
      final emailRequest = vm.checkEmail('old@example.com');
      vm.onNicknameChanged('새닉네임');
      vm.onEmailChanged('new@example.com');
      pending.complete({'available': false});
      await Future.wait([nicknameRequest, emailRequest]);
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      expect(vm.emailCheckStatus, CheckStatus.idle);
      expect(vm.nicknameErrorText, isNull);
      expect(vm.emailErrorText, isNull);
      vm.dispose();

      final delayed = Completer<Object>();
      final (nextDio, _, _) = _service((_) => delayed.future);
      final disposedVm = SignUpViewModel(MemberCheckService(nextDio));
      disposedVm.onNicknameChanged('화면이탈');
      final loading = disposedVm.checkNickname('화면이탈');
      disposedVm.dispose();
      delayed.complete({'available': true});
      await loading;
      expect(disposedVm.nicknameCheckStatus, CheckStatus.checking);
    },
  );

  test(
    'Ratings keep records when TMDB fails and reuse cached movies',
    () async {
      var failMovie = true;
      final (dio, adapter, movies) = _service((options) {
        if (options.path == '/v5/members/1/ratings') {
          return [_rating(1), _rating(2), _rating(3, movieId: 13)];
        }
        if (options.path == '/movie/13' && failMovie) {
          throw DioException(requestOptions: options);
        }
        return _movie(int.parse(options.path.split('/').last));
      });
      final vm = MyRatingsViewModel(
        RatingApiService(dio),
        movies,
        sampleMemberId,
      );
      addTearDown(vm.dispose);
      final loading = vm.load();
      expect(vm.status, MyRatingsLoadStatus.loading);
      await loading;
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.ratings.length, 3);
      expect(vm.ratings.first.movie!.title, '영화550');
      expect(vm.ratings.last.movie, isNull);
      expect(vm.message, contains('일부 영화'));
      expect(
        adapter.calls.where((call) => call.path == '/movie/550').length,
        1,
      );
      failMovie = false;
      await vm.load();
      expect(vm.ratings.last.movie!.id, 13);
      expect(vm.message, isNull);
      expect(
        adapter.calls.where((call) => call.path == '/movie/550').length,
        1,
      );
      expect(adapter.calls.where((call) => call.path == '/movie/13').length, 2);
    },
  );

  test(
    'A missing movie uses a placeholder while an empty array stays Empty',
    () async {
      var empty = false;
      final (dio, adapter, movies) = _service((options) {
        if (options.path.startsWith('/v5/')) {
          return empty ? [] : [_rating(1), _rating(2)];
        }
        throw DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
          type: DioExceptionType.badResponse,
        );
      });
      final vm = MyRatingsViewModel(
        RatingApiService(dio),
        movies,
        sampleMemberId,
      );
      addTearDown(vm.dispose);
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.ratings.every((entry) => entry.movie == null), isTrue);
      await vm.load();
      expect(
        adapter.calls.where((call) => call.path == '/movie/550').length,
        1,
      );
      empty = true;
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.empty);
      expect(vm.ratings, isEmpty);
      expect(vm.message, isNull);
    },
  );

  test('Rating errors distinguish 400, 404, and connection failure', () async {
    for (final status in [400, 404, null]) {
      final (dio, _, movies) = _service((options) {
        throw DioException(
          requestOptions: options,
          response: status == null
              ? null
              : Response(requestOptions: options, statusCode: status),
        );
      });
      final vm = MyRatingsViewModel(
        RatingApiService(dio),
        movies,
        sampleMemberId,
      );
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.error);
      expect(
        vm.message,
        contains(switch (status) {
          400 => 'memberId',
          404 => '존재하지 않는 회원',
          _ => '불러오지 못했습니다',
        }),
      );
      vm.dispose();
    }
  });

  test('New rating loads and disposal ignore older responses', () async {
    final pending = Completer<Object>();
    var calls = 0;
    final (dio, _, movies) = _service((_) {
      calls++;
      return calls == 1 ? pending.future : [];
    });
    final vm = MyRatingsViewModel(
      RatingApiService(dio),
      movies,
      sampleMemberId,
    );
    final oldLoad = vm.load();
    await Future<void>.delayed(Duration.zero);
    await vm.load();
    pending.complete([_rating(1)]);
    await oldLoad;
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(vm.ratings, isEmpty);
    vm.dispose();

    final movieResponse = Completer<Object>();
    final movieStarted = Completer<void>();
    final (otherDio, _, otherMovies) = _service((options) {
      if (options.path.startsWith('/v5/')) return [_rating(1)];
      movieStarted.complete();
      return movieResponse.future;
    });
    final disposedVm = MyRatingsViewModel(
      RatingApiService(otherDio),
      otherMovies,
      sampleMemberId,
    );
    final loading = disposedVm.load();
    await movieStarted.future;
    disposedVm.dispose();
    movieResponse.complete(_movie(550));
    await loading;
    expect(disposedVm.ratings, isEmpty);
  });

  testWidgets('Button widths differ and loading blocks taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MovieLogButton(label: '중복 확인', onPressed: () => taps++),
                MovieLogButton(
                  label: '가입하기',
                  width: double.infinity,
                  onPressed: null,
                ),
                MovieLogButton(
                  label: '다시 시도',
                  width: 120,
                  isLoading: true,
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final buttons = find.byType(MovieLogButton);
    expect(tester.getSize(buttons.at(0)).width, lessThan(360));
    expect(tester.getSize(buttons.at(1)).width, 360);
    expect(tester.getSize(buttons.at(2)).width, 120);
    expect(find.text('다시 시도'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(buttons.at(2));
    expect(taps, 0);
    await tester.tap(buttons.at(0));
    expect(taps, 1);
  });

  testWidgets(
    'Signup shows server errors and restores a duplicate without a request',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final response = Completer<Object>();
      final (dio, adapter, movies) = _service((_) => response.future);
      final router = GoRouter(
        navigatorKey: AppRouter.rootNavigatorKey,
        initialLocation: '/signup',
        routes: AppRouter.router.configuration.routes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<MemberCheckService>.value(value: MemberCheckService(dio)),
            Provider<TmdbMovieService>.value(value: movies),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final nickname = find.byType(TextFormField).at(0);
      await tester.enterText(nickname, '중복닉네임');
      await tester.pump();
      await tester.tap(find.widgetWithText(MovieLogButton, '중복 확인').first);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete({'available': false});
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      tester.state<FormState>(find.byType(Form)).validate();
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      final calls = adapter.calls.length;
      await tester.enterText(nickname, '다른닉네임');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      await tester.enterText(nickname, '중복닉네임');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(adapter.calls.length, calls);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Signup requires both checks and edits disable submission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (dio, _, movies) = _service((_) => {'available': true});
    final router = GoRouter(
      navigatorKey: AppRouter.rootNavigatorKey,
      initialLocation: '/signup',
      routes: AppRouter.router.configuration.routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MemberCheckService>.value(value: MemberCheckService(dio)),
          Provider<TmdbMovieService>.value(value: movies),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '사용가능');
    await tester.enterText(fields.at(1), 'available@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.pump();
    MovieLogButton submit() => tester.widget<MovieLogButton>(
      find.widgetWithText(MovieLogButton, '가입하기'),
    );
    expect(submit().onPressed, isNull);
    for (var index = 0; index < 2; index++) {
      final check = find.widgetWithText(MovieLogButton, '중복 확인').at(index);
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
    }
    expect(submit().onPressed, isNotNull);
    await tester.enterText(fields.at(1), 'new@example.com');
    await tester.pump();
    expect(submit().onPressed, isNull);
    expect(find.text('사용할 수 있는 이메일입니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Ratings opens above tabs, renders each state, and returns to profile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<Object>();
      var mode = 'loading';
      final (dio, _, movies) = _service((options) {
        if (!options.path.startsWith('/v5/')) return _movie(550);
        if (mode == 'loading') return pending.future;
        if (mode == 'empty') return [];
        throw DioException(requestOptions: options);
      });
      final router = GoRouter(
        navigatorKey: AppRouter.rootNavigatorKey,
        initialLocation: '/my',
        routes: AppRouter.router.configuration.routes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<RatingApiService>.value(value: RatingApiService(dio)),
            Provider<TmdbMovieService>.value(value: movies),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.ensureVisible(find.text('내가 등록한 평점'));
      await tester.tap(find.text('내가 등록한 평점'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete([_rating(1), _rating(2, comment: '좋아요')]);
      await tester.pumpAndSettle();
      expect(find.text('영화550'), findsNWidgets(2));
      expect(find.text('좋아요'), findsOneWidget);
      expect(find.text('코멘트 없음'), findsNothing);
      final vm = tester
          .element(find.byType(MyRatingsScreen))
          .read<MyRatingsViewModel>();
      mode = 'empty';
      final emptyLoad = vm.load();
      await tester.pumpAndSettle();
      await emptyLoad;
      expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
      mode = 'error';
      final errorLoad = vm.load();
      await tester.pumpAndSettle();
      await errorLoad;
      expect(find.textContaining('평점을 불러오지 못했습니다'), findsOneWidget);
      expect(tester.getSize(find.byType(MovieLogButton)).width, 120);
      mode = 'empty';
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(MyRatingsScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('내 프로필'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, dynamic> _rating(int id, {int movieId = 550, String? comment}) => {
  'ratingId': id,
  'movieId': movieId,
  'score': 5,
  'comment': comment,
  'createdAt': '2026-09-06T12:14:03.000Z',
};
