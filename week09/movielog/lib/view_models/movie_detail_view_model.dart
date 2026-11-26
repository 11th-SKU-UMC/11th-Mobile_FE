import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/movie_record_request.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/api_error.dart';
import '../data/services/movie_record_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'favorite_detail_view_model.dart';
import 'session_ratings.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

class MovieDetailViewModel extends ChangeNotifier with SafeNotify {
  MovieDetailViewModel(
    this._service,
    this._ratings, {
    required this._favorite,
    required this._records,
    required this.movieId,
    TmdbMovieDto? initialMovie,
  }) : movie = initialMovie?.id == movieId ? initialMovie : null,
       _version = _ratings.version {
    _ratings.addListener(_onRatingsChanged);
  }

  final TmdbMovieService _service;
  final SessionRatings _ratings;
  final FavoriteDetailViewModel _favorite;
  final MovieRecordApiService _records;
  final int movieId;
  final int _version;
  bool _submitting = false;

  bool get _active => !isDisposed && _ratings.isCurrent(_version);
  RatingDto? get myRating => _active ? _ratings.forMovie(movieId) : null;
  bool get canCreateRating =>
      _active && myRating == null && !_submitting && _favorite.canUseForRating;

  TmdbMovieDto? movie;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.idle;
  String? message;
  void _onRatingsChanged() => notifyIfAlive();

  Future<void> loadMovie() async {
    if (!_active || status == MovieDetailLoadStatus.loading) return;
    status = MovieDetailLoadStatus.loading;
    message = null;
    notifyIfAlive();
    try {
      final result = await _service.fetchMovieDetails(movieId);
      if (!_active) return;
      movie = result;
      status = MovieDetailLoadStatus.success;
    } catch (_) {
      if (!_active) return;
      status = MovieDetailLoadStatus.error;
      message = '영화 상세 정보를 불러오지 못했어요.';
    }
    notifyIfAlive();
  }

  Future<void> createRating({
    required int score,
    String? comment,
    required bool addToFavorites,
  }) async {
    if (!canCreateRating) throw const ApiException('평점을 등록할 수 없습니다.');
    _submitting = true;
    notifyIfAlive();
    try {
      final request = CreateRatingRequest(
        movieId: movieId,
        score: score,
        comment: comment,
      );
      if (_favorite.isFavorite == true) {
        await _ratings.create(_version, request, movie);
      } else {
        final result = await _records.create(
          MovieRecordRequest(rating: request, addToFavorites: addToFavorites),
        );
        _ratings.rememberCreated(_version, result.rating, movie);
      }
    } finally {
      if (_active) {
        _submitting = false;
        notifyIfAlive();
      }
    }
  }

  @override
  void dispose() {
    _ratings.removeListener(_onRatingsChanged);
    super.dispose();
  }
}
