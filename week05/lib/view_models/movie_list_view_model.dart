import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._movieService);

  final TmdbMovieService _movieService;

  static const int maxMovieCount = 30;

  bool isLoading = false;
  String? errorMessage;

  List<TmdbGenreDto> genres = [];
  List<TmdbMovieDto> movies = [];

  int? selectedGenreId;

  Future<void> initialize() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      genres = await _movieService.fetchGenres();

      await _loadMoviesInternal();
    } catch (e) {
      errorMessage = '영화 정보를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGenre(int? genreId) async {
    if (isLoading) {
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

    isLoading = true;
    errorMessage = null;
    movies = [];

    notifyListeners();

    try {
      await _loadMoviesInternal();
    } catch (e) {
      errorMessage = '영화 목록을 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await loadMovies();
  }

  Future<void> _loadMoviesInternal() async {
    final movieMap = <int, TmdbMovieDto>{};

    var currentPage = 1;
    var totalPages = 1;

    while (movieMap.length < maxMovieCount && currentPage <= totalPages) {
      final result = await _movieService.discoverMovies(
        page: currentPage,
        genreId: selectedGenreId,
      );

      totalPages = result.totalPages;

      for (final movie in result.results) {
        movieMap[movie.id] = movie;

        if (movieMap.length >= maxMovieCount) {
          break;
        }
      }

      currentPage++;
    }

    movies = movieMap.values.take(maxMovieCount).toList();
  }
}
