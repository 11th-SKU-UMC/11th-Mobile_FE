import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/api_error.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';

class SessionRatings extends ChangeNotifier {
  SessionRatings(this._auth, this._service) {
    _version = _auth.sessionVersion;
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  final RatingApiService _service;
  final Map<int, RatingWithMovie> _ratingsByMovie = {};
  late int _version;
  bool _disposed = false;

  List<RatingWithMovie> get entries =>
      List.unmodifiable(_ratingsByMovie.values);
  RatingDto? forMovie(int movieId) => _ratingsByMovie[movieId]?.rating;

  void _onAuthChanged() {
    if (_version == _auth.sessionVersion) return;
    _version = _auth.sessionVersion;
    if (_ratingsByMovie.isEmpty) return;
    _ratingsByMovie.clear();
    notifyListeners();
  }

  bool isCurrent(int version) => !_disposed && _auth.isSignedInSession(version);
  int get version => _version;

  void _requireSession(int version) {
    if (!isCurrent(version)) throw const ApiException('로그인이 필요합니다.');
  }

  Future<void> create(
    int version,
    CreateRatingRequest request,
    TmdbMovieDto? movie,
  ) async {
    _requireSession(version);
    final rating = await _service.createRating(request);
    if (!isCurrent(version)) return;
    _ratingsByMovie[rating.movieId] = RatingWithMovie(
      rating: rating,
      movie: movie?.id == rating.movieId ? movie : null,
    );
    notifyListeners();
  }

  Future<void> update(
    int version,
    RatingDto original,
    int score,
    String? comment,
  ) async {
    _requireSession(version);
    try {
      final rating = await _service.updateRating(
        ratingId: original.ratingId,
        score: score,
        comment: comment,
      );
      if (!isCurrent(version)) return;
      final movie = _ratingsByMovie[rating.movieId]?.movie;
      _ratingsByMovie[rating.movieId] = RatingWithMovie(
        rating: rating,
        movie: movie,
      );
      notifyListeners();
    } catch (error) {
      if (isCurrent(version) && apiErrorCode(error) == 'RATING404_1') {
        _remove(original);
      }
      rethrow;
    }
  }

  Future<void> delete(int version, RatingDto rating) async {
    _requireSession(version);
    try {
      await _service.deleteRating(rating.ratingId);
    } catch (error) {
      if (isCurrent(version) && apiErrorCode(error) == 'RATING404_1') {
        _remove(rating);
      }
      rethrow;
    }
    if (isCurrent(version)) _remove(rating);
  }

  void _remove(RatingDto rating) {
    if (forMovie(rating.movieId)?.ratingId != rating.ratingId) return;
    _ratingsByMovie.remove(rating.movieId);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
