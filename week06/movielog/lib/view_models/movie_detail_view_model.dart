import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_rating.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service, {
    required this.movieId,
    TmdbMovieDto? initialMovie,
  }) : movie = initialMovie?.id == movieId ? initialMovie : null;

  final TmdbMovieService _service;
  final int movieId;
  TmdbMovieDto? movie;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.idle;
  String? message;
  bool isFavorite = false;
  MovieRating? myRating;
  bool _disposed = false;

  Future<void> loadMovie() async {
    if (_disposed || status == MovieDetailLoadStatus.loading) return;
    status = MovieDetailLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final result = await _service.fetchMovieDetails(movieId);
      if (_disposed) return;
      movie = result;
      status = MovieDetailLoadStatus.success;
    } catch (_) {
      if (_disposed) return;
      status = MovieDetailLoadStatus.error;
      message = '영화 상세 정보를 불러오지 못했어요.';
    }
    notifyListeners();
  }

  void toggleFavorite() {
    if (_disposed) return;
    isFavorite = !isFavorite;
    notifyListeners();
  }

  void setRating(MovieRating rating) {
    if (_disposed ||
        rating.movieId != movieId ||
        rating.score < 0.5 ||
        rating.score > 5) {
      return;
    }
    myRating = rating;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
