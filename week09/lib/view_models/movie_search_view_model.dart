import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

class MovieSearchViewModel extends ChangeNotifier {
  MovieSearchViewModel(this._movieService);

  final TmdbMovieService _movieService;

  bool isLoading = false;
  bool isLoadingMore = false;

  String? errorMessage;

  String query = '';
  List<TmdbMovieDto> movies = [];

  int currentPage = 1;
  int totalPages = 1;

  int _generation = 0;

  bool get hasSearched => query.isNotEmpty;

  bool get canLoadMore =>
      currentPage < totalPages && !isLoadingMore;

  Future<void> search(String value) async {
    final trimmed = value.trim();

    if (trimmed.isEmpty || isLoading) {
      return;
    }

    query = trimmed;

    final requestGeneration = ++_generation;

    isLoading = true;
    errorMessage = null;

    movies = [];
    currentPage = 1;
    totalPages = 1;

    notifyListeners();

    try {
      final result = await _movieService.searchMovies(
        query: query,
        page: 1,
      );

      if (requestGeneration != _generation) {
        return;
      }

      movies = result.results;
      currentPage = result.page;
      totalPages = result.totalPages;
    } catch (e) {
    if (requestGeneration != _generation) {
        return;
    }

    errorMessage =
        '검색 결과를 불러오지 못했습니다.';
    } finally {
        if (requestGeneration == _generation) {
            isLoading = false;
            notifyListeners();
        }
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;

    isLoadingMore = true;
    errorMessage = null;
    notifyListeners();

    final requestGeneration = _generation;

    try {
      final result = await _movieService.searchMovies(
        query: query,
        page: currentPage + 1,
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
      errorMessage =
          '다음 검색 결과를 불러오지 못했습니다.';
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}