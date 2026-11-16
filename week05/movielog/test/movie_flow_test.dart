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
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie_rating.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/screens/movies_screen.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

typedef _Responder = FutureOr<Map<String, dynamic>> Function(RequestOptions);

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
}
