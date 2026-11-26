import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 목록을 어떤 TMDB API로 채울지 정합니다.
enum PagedMoviesMode {
  /// 영화 목록 화면: Discover API(장르 필터)
  discover,

  /// 검색 화면: Search API. 빈 검색어는 서버에 보내지 않습니다.
  search,
}

/// TMDB Discover/Search를 page 단위로 불러오는 "더 보기" 목록 상태입니다.
///
/// 영화 목록과 검색 화면이 각각 별도 인스턴스를 사용합니다.
///
/// - 첫 page 성공 → 목록 교체, 실패 → [LoadPhase.error]
/// - 다음 page 성공 → 같은 movieId를 빼고 append, [nextPage] 증가
/// - 다음 page 실패 → 목록과 [nextPage]를 유지해 같은 page를 다시 요청
/// - 장르·검색어·새로고침 → [_requestGeneration]을 올려 이전 조건의 늦은 응답을 무시
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({
    required this.tmdbApi,
    this.mode = PagedMoviesMode.discover,
  });

  final TmdbMovieService tmdbApi;
  final PagedMoviesMode mode;

  /// TMDB는 page 1~500만 허용합니다. total_pages가 더 커도 501은 요청하지 않습니다.
  static const maxTmdbPage = 500;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> movies = [];

  /// 다음에 요청할 page입니다. 실패하면 올리지 않습니다.
  int nextPage = 1;

  /// 서버 total_pages와 [maxTmdbPage] 중 작은 값입니다.
  int totalPages = 1;
  int totalResults = 0;

  bool isLoadingMore = false;
  String? errorMessage;

  /// 기존 목록을 지우지 않고 하단 footer에 보여 줄 오류입니다.
  String? loadMoreError;

  int _requestGeneration = 0;
  ({List<int> genreIds, String query}) _condition = (
    genreIds: const [],
    query: '',
  );

  bool get hasMore => nextPage <= totalPages;
  ({List<int> genreIds, String query}) get condition => _condition;

  /// 조건(장르·검색어)이 바뀌거나 새로고침할 때 호출합니다. 첫 page부터 다시 요청합니다.
  Future<void> loadInitial({
    List<int> genreIds = const [],
    String query = '',
  }) async {
    if (isDisposed) return;
    _condition = (genreIds: List.unmodifiable(genreIds), query: query.trim());
    // 이전 조건의 응답·오류·finally가 새 상태를 덮어쓰지 않도록 번호를 올립니다.
    final generation = ++_requestGeneration;
    movies.clear();
    nextPage = 1;
    totalPages = 1;
    totalResults = 0;
    isLoadingMore = false;
    loadMoreError = null;
    errorMessage = null;

    if (mode == PagedMoviesMode.search && _condition.query.isEmpty) {
      // 빈 검색어는 서버에 보내지 않고 처음 상태로 돌아갑니다.
      phase = LoadPhase.idle;
      notifyIfAlive();
      return;
    }

    phase = LoadPhase.loading;
    notifyIfAlive();
    try {
      final page = await _fetchPage(1, _condition);
      if (generation != _requestGeneration || isDisposed) return;
      _applyFirstPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      phase = LoadPhase.error;
      errorMessage = mode == PagedMoviesMode.search
          ? '검색 결과를 불러오지 못했습니다.'
          : '영화 목록을 불러오지 못했습니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) notifyIfAlive();
    }
  }

  /// 같은 조건으로 첫 page부터 다시 불러옵니다(재시도·당겨서 새로고침).
  Future<void> refresh() =>
      loadInitial(genreIds: _condition.genreIds, query: _condition.query);

  /// "더 보기"·무한 스크롤에서 호출합니다. 실패해도 [nextPage]를 올리지 않아 같은 page를 재시도합니다.
  Future<void> loadNextPage() async {
    if (isDisposed || isLoadingMore || !hasMore || phase != LoadPhase.ready) {
      return;
    }
    final generation = _requestGeneration;
    final pageToLoad = nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(pageToLoad, _condition);
      if (generation != _requestGeneration || isDisposed) return;
      _appendPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      loadMoreError = '$pageToLoad페이지를 불러오지 못했습니다. 같은 페이지를 다시 요청합니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(
    int page,
    ({List<int> genreIds, String query}) condition,
  ) async {
    final result = mode == PagedMoviesMode.search
        ? await tmdbApi.searchMovies(page: page, query: condition.query)
        : await tmdbApi.discoverMovies(
            page: page,
            genreIds: condition.genreIds,
          );
    if (result.page != page || result.page < 1 || result.totalPages < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _applyFirstPage(TmdbMoviePageDto page) {
    movies
      ..clear()
      ..addAll(_dedupe(page.results));
    _applyPageMeta(page);
    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  void _appendPage(TmdbMoviePageDto page) {
    movies.addAll(_dedupe(page.results));
    _applyPageMeta(page);
  }

  void _applyPageMeta(TmdbMoviePageDto page) {
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    totalResults = page.totalResults;
    // 성공한 응답을 반영할 때만 다음 page 번호를 올립니다.
    nextPage = page.page + 1;
  }

  /// TMDB는 page가 바뀌어도 같은 영화를 다시 줄 수 있으므로 이미 가진 movieId를 뺍니다.
  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = movies.map((movie) => movie.id).toSet();
    return incoming
        .where((movie) => seen.add(movie.id))
        .toList(growable: false);
  }
}
