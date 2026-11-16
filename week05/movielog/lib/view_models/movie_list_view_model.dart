import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;
  int failureVersion = 0;

  bool _genresLoaded = false;
  bool _disposed = false;
  bool _keepMoviesWhileLoading = false;
  int _requestVersion = 0;

  bool get isLoading => status == MovieListLoadStatus.loading;
  bool get showMovies =>
      movies.isNotEmpty && (!isLoading || _keepMoviesWhileLoading);
  bool get showingPreviousResults =>
      status == MovieListLoadStatus.error && movies.isNotEmpty;

  Future<void> loadInitial() => _load();

  Future<void> selectGenres(List<int>? genreIds) async {
    if (_disposed || isLoading) return;
    final ids = genreIds?.toSet().toList();
    ids?.sort();
    final normalized = ids == null || ids.isEmpty
        ? null
        : List<int>.unmodifiable(ids);
    if (listEquals(normalized, selectedGenreIds) &&
        status != MovieListLoadStatus.error) {
      return;
    }
    selectedGenreIds = normalized;
    await _load();
  }

  Future<void> refresh() => _load(keepMovies: true);

  Future<void> retry() => _load(keepMovies: movies.isNotEmpty);

  Future<void> _load({bool keepMovies = false}) async {
    if (_disposed || isLoading) return;
    final version = ++_requestVersion;
    final genreIds = selectedGenreIds;
    _keepMoviesWhileLoading = keepMovies;
    message = null;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      if (!_genresLoaded) {
        final result = await _service.fetchGenres();
        if (!_isCurrent(version)) return;
        genres = List.unmodifiable(result);
        _genresLoaded = true;
      }

      final byId = <int, TmdbMovieDto>{};
      var pageNumber = 1;
      while (byId.length < 30) {
        final page = await _service.discoverMovies(
          page: pageNumber,
          genreIds: genreIds,
        );
        if (!_isCurrent(version)) return;
        for (final movie in page.results) {
          byId.putIfAbsent(movie.id, () => movie);
          if (byId.length == 30) break;
        }
        if (page.results.isEmpty ||
            pageNumber >= page.totalPages ||
            pageNumber >= 500) {
          break;
        }
        pageNumber++;
      }

      movies = List.unmodifiable(byId.values);
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 연결을 확인하고 다시 시도해 주세요.';
      failureVersion++;
    }

    if (_isCurrent(version)) notifyListeners();
  }

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
