import 'package:flutter/foundation.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 영화 목록(Discover)과 검색(Search)이 함께 쓰는 page 단위 ViewModel입니다.
/// 목록 화면과 검색 화면은 각각 별도의 인스턴스를 만듭니다.
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi});

  final TmdbMovieService tmdbApi;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> movies = [];
  int nextPage = 1; // 다음에 요청할 page. 실패하면 올리지 않습니다.
  int totalPages = 1;
  static const maxTmdbPage = 500; // TMDB는 500page까지만 허용합니다.
  bool isLoadingMore = false;
  bool get hasMore => nextPage <= totalPages;
  String? errorMessage;
  String? loadMoreError;

  // 5주차 Challenge(장르 다중 선택)를 유지하기 위한 상태입니다.
  List<TmdbGenreDto> genres = const [];
  List<int> selectedGenreIds = const []; // 비어 있으면 "전체"

  /// 첫 로딩 중에는 장르 변경을 막습니다.
  bool get isBusy => phase == LoadPhase.loading;

  int _requestGeneration = 0; // 조건이 바뀔 때마다 올려 늦은 응답을 걸러냅니다.
  ({List<int> genreIds, String query}) _condition =
      (genreIds: const [], query: '');

  /// 장르 목록 조회. 실패해도 영화 목록은 막지 않습니다.
  Future<void> loadGenres() async {
    try {
      final result = await tmdbApi.fetchGenres();
      if (isDisposed) return;
      genres = result;
    } catch (_) {
      if (isDisposed) return;
      genres = const [];
    }
    notifyIfAlive();
  }

  /// 장르 다중 선택 적용. 목록·page·추가로딩 상태를 비우고 첫 page부터 다시 조회합니다.
  Future<void> applyGenres(List<int> genreIds) async {
    if (isBusy) return;
    final next = [...genreIds]..sort();
    if (listEquals(next, selectedGenreIds)) return;
    await loadInitial(genreIds: next);
  }

  Future<void> loadInitial({
    List<int> genreIds = const [],
    String query = '',
  }) async {
    if (isDisposed) return;
    selectedGenreIds = [...genreIds];
    _condition = (genreIds: [...genreIds], query: query.trim());
    final generation = ++_requestGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;
    movies.clear();
    nextPage = 1;
    totalPages = 1;
    notifyIfAlive();
    try {
      final page = await _fetchPage(1, _condition);
      if (generation != _requestGeneration || isDisposed) return;
      _applyFirstPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      phase = LoadPhase.error;
      errorMessage = _condition.query.isEmpty
          ? '영화 목록을 불러오지 못했습니다.'
          : '검색 결과를 불러오지 못했습니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) notifyIfAlive();
    }
  }

  // 실패해도 nextPage를 올리지 않아 같은 page를 다시 요청할 수 있습니다.
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
      loadMoreError = '다음 페이지를 불러오지 못했습니다. 같은 페이지를 다시 요청합니다.';
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
    final TmdbMoviePageDto result;
    if (condition.query.isNotEmpty) {
      result = await tmdbApi.searchMovies(page: page, query: condition.query);
    } else {
      // with_genres는 장르 id를 OR(|)로 연결합니다. 선택이 없으면 보내지 않습니다.
      final withGenres =
          condition.genreIds.isEmpty ? null : condition.genreIds.join('|');
      result = await tmdbApi.discoverMovies(page: page, withGenres: withGenres);
    }
    if (result.page != page || result.page < 1 || result.totalPages < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _applyFirstPage(TmdbMoviePageDto page) {
    movies
      ..clear()
      ..addAll(_dedupe(page.results));
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    nextPage = page.page + 1;
    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  void _appendPage(TmdbMoviePageDto page) {
    movies.addAll(_dedupe(page.results));
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    nextPage = page.page + 1;
  }

  // 같은 movieId는 한 번만 담습니다.
  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = movies.map((movie) => movie.id).toSet();
    return incoming.where((movie) => seen.add(movie.id)).toList(growable: false);
  }
}
