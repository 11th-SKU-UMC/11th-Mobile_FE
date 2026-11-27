import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

/// Discover·Search 요청을 기록하고, 테스트가 정한 handler로 응답한다.
class _FakeTmdb extends TmdbMovieService {
  _FakeTmdb() : super(Dio());

  Future<TmdbMoviePageDto> Function(int page, int? genreId)? discover;
  Future<TmdbMoviePageDto> Function(int page, String query)? search;
  final List<({int page, int? genreId})> discoverCalls = [];
  final List<({int page, String query})> searchCalls = [];

  @override
  Future<TmdbMoviePageDto> discoverMovies({required int page, int? genreId}) {
    discoverCalls.add((page: page, genreId: genreId));
    return discover!(page, genreId);
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required int page,
    required String query,
  }) {
    searchCalls.add((page: page, query: query));
    return search!(page, query);
  }
}

TmdbMovieDto _movie(int id) => TmdbMovieDto(
  id: id,
  title: '영화 $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: null,
  genreIds: const [],
  voteAverage: 0,
  popularity: 0,
);

TmdbMoviePageDto _page(int page, List<int> ids, {int totalPages = 3}) =>
    TmdbMoviePageDto(
      page: page,
      results: ids.map(_movie).toList(),
      totalPages: totalPages,
      totalResults: totalPages * ids.length,
    );

DioException _networkError() => DioException(
  requestOptions: RequestOptions(path: '/discover/movie'),
  type: DioExceptionType.connectionError,
);

List<int> _ids(PagedMoviesViewModel vm) => vm.movies.map((m) => m.id).toList();

void main() {
  late _FakeTmdb tmdb;
  late PagedMoviesViewModel vm;

  setUp(() {
    tmdb = _FakeTmdb();
    vm = PagedMoviesViewModel(tmdbApi: tmdb);
  });

  tearDown(() => vm.dispose());

  group('다음 page 실패', () {
    test('실패하면 목록과 nextPage를 유지하고, 재시도는 같은 page를 다시 요청한다', () async {
      tmdb.discover = (page, _) async => _page(page, [page * 10 + 1]);
      await vm.loadInitial();
      expect(_ids(vm), [11]);
      expect(vm.nextPage, 2);

      tmdb.discover = (page, _) async => throw _networkError();
      await vm.loadNextPage();

      expect(vm.loadMoreError, PagedMoviesViewModel.nextPageFailedMessage);
      expect(vm.phase, LoadPhase.ready);
      expect(_ids(vm), [11]);
      expect(vm.nextPage, 2);
      expect(vm.isLoadingMore, isFalse);

      tmdb.discover = (page, _) async => _page(page, [page * 10 + 1]);
      await vm.loadNextPage();

      expect(tmdb.discoverCalls.map((c) => c.page), [1, 2, 2]);
      expect(_ids(vm), [11, 21]);
      expect(vm.nextPage, 3);
      expect(vm.loadMoreError, isNull);
    });

    test('마지막 page 뒤에는 더 요청하지 않는다', () async {
      tmdb.discover = (page, _) async => _page(page, [page], totalPages: 1);
      await vm.loadInitial();
      expect(vm.hasMore, isFalse);

      await vm.loadNextPage();
      expect(tmdb.discoverCalls, hasLength(1));
    });

    test('total_pages가 500보다 커도 500까지만 조회 가능하다', () async {
      tmdb.discover = (page, _) async => _page(page, [page], totalPages: 900);
      await vm.loadInitial();
      expect(vm.totalPages, PagedMoviesViewModel.maxTmdbPage);
    });
  });

  group('조건 변경 시 늦은 응답 무시', () {
    test('장르를 바꾼 뒤 이전 장르의 첫 page가 늦게 와도 새 목록에 섞이지 않는다', () async {
      final slowAction = Completer<TmdbMoviePageDto>();
      tmdb.discover = (page, genreId) =>
          genreId == 28 ? slowAction.future : Future.value(_page(page, [35]));

      final first = vm.loadInitial(genreId: 28);
      final second = vm.loadInitial(genreId: 35);
      await second;
      expect(_ids(vm), [35]);

      slowAction.complete(_page(1, [28]));
      await first;

      expect(vm.genreId, 35);
      expect(_ids(vm), [35]);
      expect(vm.phase, LoadPhase.ready);
    });

    test('이전 조건의 다음 page 응답·오류는 버리고 추가 로딩 상태도 남기지 않는다', () async {
      tmdb.discover = (page, _) async => _page(page, [page]);
      await vm.loadInitial();

      final slowNext = Completer<TmdbMoviePageDto>();
      tmdb.discover = (page, _) => slowNext.future;
      final loadingMore = vm.loadNextPage();
      expect(vm.isLoadingMore, isTrue);

      tmdb.search = (page, query) async => _page(page, [900]);
      await vm.loadInitial(query: '  인셉션 ');
      expect(tmdb.searchCalls.single, (page: 1, query: '인셉션'));
      expect(vm.isLoadingMore, isFalse);

      slowNext.completeError(_networkError());
      await loadingMore;

      expect(_ids(vm), [900]);
      expect(vm.loadMoreError, isNull);
      expect(vm.isLoadingMore, isFalse);
      expect(vm.nextPage, 2);
    });

    test('검색어를 바꾸면 이전 검색어의 늦은 오류가 새 결과를 오류로 바꾸지 않는다', () async {
      final slowOld = Completer<TmdbMoviePageDto>();
      tmdb.search = (page, query) =>
          query == '이전' ? slowOld.future : Future.value(_page(page, [7]));

      final old = vm.loadInitial(query: '이전');
      await vm.loadInitial(query: '새 검색');
      slowOld.completeError(_networkError());
      await old;

      expect(vm.phase, LoadPhase.ready);
      expect(vm.errorMessage, isNull);
      expect(_ids(vm), [7]);
    });

    test('dispose 뒤에 도착한 응답은 반영하지 않고 예외도 내지 않는다', () async {
      final slow = Completer<TmdbMoviePageDto>();
      tmdb.discover = (page, _) => slow.future;
      final local = PagedMoviesViewModel(tmdbApi: tmdb);
      final loading = local.loadInitial();
      local.dispose();

      slow.complete(_page(1, [1]));
      await loading;
      expect(local.movies, isEmpty);
    });
  });

  group('중복 제거', () {
    test('다음 page에 이미 있는 movieId가 오면 한 번만 보여준다', () async {
      tmdb.discover = (page, _) async =>
          page == 1 ? _page(1, [1, 2, 3]) : _page(2, [3, 4, 1, 5]);
      await vm.loadInitial();
      await vm.loadNextPage();

      expect(_ids(vm), [1, 2, 3, 4, 5]);
    });

    test('같은 page 안의 중복도 제거한다', () async {
      tmdb.discover = (page, _) async => _page(page, [1, 1, 2]);
      await vm.loadInitial();

      expect(_ids(vm), [1, 2]);
    });
  });
}
