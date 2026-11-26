import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/rating_api_service.dart';
import 'signup_view_model.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._favoriteService,
    this.memberId,
    this.movie,
  );

  final RatingApiService _ratingService;
  final FavoriteApiService _favoriteService;

  final int? memberId;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  bool isFavorite = false;
  bool isFavoriteLoading = false;
  String? favoriteMessage;

  bool _disposed = false;

  Future<void> loadFavorite() async {
    if (isFavoriteLoading) return;

    isFavoriteLoading = true;
    favoriteMessage = null;
    notifyListeners();

    try {
      final result = await _favoriteService.checkFavorite(
        movieId: movie.id,
      );

      if (_disposed) return;

      isFavorite = result.isFavorite;
    } on DioException catch (error) {
      if (_disposed) return;

      favoriteMessage = writeErrorMessage(error);
    } finally {
      if (!_disposed) {
        isFavoriteLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite() async {
    if (isFavoriteLoading) return;

    isFavoriteLoading = true;
    favoriteMessage = null;
    notifyListeners();

    try {
      if (isFavorite) {
        await _favoriteService.deleteFavorite(
          movieId: movie.id,
        );

        if (_disposed) return;

        isFavorite = false;
      } else {
        await _favoriteService.createFavorite(
          movieId: movie.id,
        );

        if (_disposed) return;

        isFavorite = true;
      }
    } on DioException catch (error) {
      if (_disposed) return;

      favoriteMessage = writeErrorMessage(error);
    } finally {
      if (!_disposed) {
        isFavoriteLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> createRating({
    required int score,
    String? comment,
  }) async {
    final id = memberId;

    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '회원 로그인이 필요합니다.';
      notifyListeners();
      return;
    }

    if (submitStatus == SubmitStatus.submitting) {
      return;
    }

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );

      if (_disposed) return;

      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;

      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}