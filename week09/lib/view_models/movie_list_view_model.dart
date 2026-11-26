import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._movieService);

  final TmdbMovieService _movieService;

  bool isLoading = false;
  bool isLoadingMore = false;

  String? errorMessage;
  String? loadMoreErrorMessage;

  List<TmdbGenreDto> genres = [];
  List<TmdbMovieDto> movies = [];

  int? selectedGenreId;

  int currentPage = 1;
  int totalPages = 1;

  int _generation = 0;

  bool get canLoadMore =>
      currentPage < totalPages && !isLoadingMore;

  Future<void> initialize() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      genres = await _movieService.fetchGenres();

      final result =
          await _movieService.discoverMovies(
        page: 1,
        genreId: selectedGenreId,
      );

      currentPage = result.page;
      totalPages = result.totalPages;
      movies = result.results;
    } catch (e) {
      errorMessage =
          '영화 정보를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGenre(int? genreId) async {
    if (isLoading || isLoadingMore) {
      return;
    }

    if (selectedGenreId == genreId) {
      return;
    }

    selectedGenreId = genreId;

    await loadMovies();
  }

  Future<void> loadMovies() async {
    if (isLoading) return;

    final requestGeneration = ++_generation;

    isLoading = true;
    errorMessage = null;
    loadMoreErrorMessage = null;

    movies = [];
    currentPage = 1;
    totalPages = 1;

    notifyListeners();

    try {
      final result =
          await _movieService.discoverMovies(
        page: 1,
        genreId: selectedGenreId,
      );

      if (requestGeneration != _generation) {
        return;
      }

      currentPage = result.page;
      totalPages = result.totalPages;
      movies = result.results;
    } catch (e) {
      if (requestGeneration != _generation) {
        return;
      }

      errorMessage =
          '영화 목록을 불러오지 못했습니다.';
    } finally {
      if (requestGeneration == _generation) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore) {
      return;
    }

    isLoadingMore = true;
    loadMoreErrorMessage = null;
    notifyListeners();

    final requestGeneration = _generation;

    try {
      final nextPage = currentPage + 1;

      final result =
          await _movieService.discoverMovies(
        page: nextPage,
        genreId: selectedGenreId,
      );

      if (requestGeneration != _generation) {
        return;
      }

      final existingIds =
          movies.map((movie) => movie.id).toSet();

      final newMovies = result.results
          .where(
            (movie) =>
                !existingIds.contains(movie.id),
          )
          .toList();

      movies.addAll(newMovies);

      currentPage = result.page;
      totalPages = result.totalPages;
    } catch (e) {
      if (requestGeneration != _generation) {
        return;
      }

      loadMoreErrorMessage =
          '다음 페이지를 불러오지 못했습니다.';
    } finally {
      if (requestGeneration == _generation) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async {
    await loadMovies();
  }
}