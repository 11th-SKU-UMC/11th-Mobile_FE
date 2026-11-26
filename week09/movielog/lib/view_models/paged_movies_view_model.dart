import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(this._service, {this.searchMode = false});

  final TmdbMovieService _service;
  final bool searchMode;
  ({List<int> genreIds, String query}) _criteria = (
    genreIds: const [],
    query: '',
  );
  int _generation = 0;
  int _nextPage = 1;
  int _totalPages = 0;
  bool _loadingGenres = false;
  bool _genresLoaded = false;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int> get genreIds => _criteria.genreIds;

  LoadPhase phase = LoadPhase.idle;
  bool isLoadingMore = false;
  String? loadMoreError;
  bool get hasMore => phase == LoadPhase.ready && _nextPage <= _totalPages;

  Future<void> loadInitial() async {
    if (isDisposed) return;
    final generation = ++_generation;
    final criteria = _criteria;
    movies = const [];
    _nextPage = 1;
    _totalPages = 0;
    isLoadingMore = false;
    loadMoreError = null;
    phase = searchMode && criteria.query.isEmpty
        ? LoadPhase.idle
        : LoadPhase.loading;
    notifyIfAlive();
    if (phase == LoadPhase.idle) return;

    try {
      final page = await _fetch(1, criteria);
      if (!_isCurrent(generation)) return;
      _applyPage(page, 1);
      phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (_) {
      if (!_isCurrent(generation)) return;
      phase = LoadPhase.error;
    }
    notifyIfAlive();
  }

  Future<void> selectGenres(List<int> ids) async {
    if (isDisposed) return;
    final unique = ids.toSet().toList()..sort();
    if (listEquals(unique, genreIds) && phase != LoadPhase.error) return;
    _criteria = (genreIds: List.unmodifiable(unique), query: '');
    await loadInitial();
  }

  Future<void> submitQuery(String value) async {
    if (isDisposed) return;
    final query = value.trim();
    if (query == _criteria.query && phase != LoadPhase.error) return;
    _criteria = (genreIds: const [], query: query);
    await loadInitial();
  }

  Future<void> loadGenres() async {
    if (isDisposed || _genresLoaded || _loadingGenres) return;
    _loadingGenres = true;
    try {
      final loaded = await _service.fetchGenres();
      if (isDisposed) return;
      genres = List.unmodifiable(loaded);
      _genresLoaded = true;
      notifyIfAlive();
    } catch (_) {
      // 목록은 장르 정보 없이도 표시하고 다음 새로고침에서 장르를 다시 불러옵니다.
    } finally {
      _loadingGenres = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isDisposed || !hasMore || isLoadingMore) return;
    final generation = _generation;
    final pageNumber = _nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetch(pageNumber, _criteria);
      if (!_isCurrent(generation)) return;
      _applyPage(page, pageNumber);
    } catch (_) {
      if (!_isCurrent(generation)) return;
      loadMoreError = '다음 영화를 불러오지 못했습니다.';
    } finally {
      if (_isCurrent(generation)) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  bool _isCurrent(int generation) => !isDisposed && generation == _generation;

  Future<TmdbMoviePageDto> _fetch(
    int page,
    ({List<int> genreIds, String query}) criteria,
  ) => searchMode
      ? _service.searchMovies(criteria.query, page: page)
      : _service.discoverMovies(page: page, genreIds: criteria.genreIds);

  void _applyPage(TmdbMoviePageDto page, int pageNumber) {
    final seen = movies.map((movie) => movie.id).toSet();
    movies = List.unmodifiable([
      ...movies,
      for (final movie in page.results)
        if (seen.add(movie.id)) movie,
    ]);
    _nextPage = pageNumber + 1;
    _totalPages = page.totalPages.clamp(0, 500);
  }
}
