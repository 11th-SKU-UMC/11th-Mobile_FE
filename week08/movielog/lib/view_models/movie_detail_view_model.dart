import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/api_error.dart';
import '../data/services/tmdb_movie_service.dart';
import 'session_ratings.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this._ratings, {
    required this.movieId,
    TmdbMovieDto? initialMovie,
  }) : movie = initialMovie?.id == movieId ? initialMovie : null,
       _version = _ratings.version {
    _ratings.addListener(_onRatingsChanged);
  }

  final TmdbMovieService _service;
  final SessionRatings _ratings;
  final int movieId;
  final int _version;
  bool _submitting = false;
  bool _disposed = false;

  bool get _active => !_disposed && _ratings.isCurrent(_version);
  RatingDto? get myRating => _active ? _ratings.forMovie(movieId) : null;
  bool get canCreateRating => _active && myRating == null && !_submitting;

  TmdbMovieDto? movie;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.idle;
  String? message;
  bool isFavorite = false;

  void _onRatingsChanged() => notifyListeners();

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

  Future<void> createRating({required int score, String? comment}) async {
    if (!canCreateRating) throw const ApiException('평점을 등록할 수 없습니다.');
    _submitting = true;
    notifyListeners();
    try {
      await _ratings.create(
        _version,
        CreateRatingRequest(movieId: movieId, score: score, comment: comment),
        movie,
      );
    } finally {
      if (_active) {
        _submitting = false;
        notifyListeners();
      }
    }
  }

  void toggleFavorite() {
    if (_disposed) return;
    isFavorite = !isFavorite;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ratings.removeListener(_onRatingsChanged);
    super.dispose();
  }
}
