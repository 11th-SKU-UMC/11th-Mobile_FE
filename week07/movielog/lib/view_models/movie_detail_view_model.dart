import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_rating.dart';
import '../data/models/rating_request.dart';
import '../data/services/api_error.dart';
import '../data/services/rating_api_service.dart';
import 'sign_up_view_model.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service, {
    required this.movieId,
    TmdbMovieDto? initialMovie,
    this.ratingService,
    this.memberId,
  }) : movie = initialMovie?.id == movieId ? initialMovie : null;

  final TmdbMovieService _service;
  final int movieId;
  final RatingApiService? ratingService;
  final int? memberId;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool get canCreateRating =>
      memberId != null &&
      myRating == null &&
      submitStatus != SubmitStatus.submitting;
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

  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) {
      throw const ApiException('이미 저장 중입니다.');
    }
    final id = memberId;
    final service = ratingService;
    if (id == null || service == null) {
      throw const ApiException('먼저 학습용 회원가입을 완료해 주세요.');
    }
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await service.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movieId,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      myRating = MovieRating(movieId: movieId, score: score.toDouble());
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (!_disposed) {
        submitStatus = SubmitStatus.error;
        submitMessage = apiErrorMessage(error);
        notifyListeners();
      }
      rethrow;
    }
    if (!_disposed) notifyListeners();
  }

  void toggleFavorite() {
    if (_disposed) return;
    isFavorite = !isFavorite;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
