import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsState {
  idle,
  loading,
  success,
  empty,
  error,
}

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel({
    required this.ratingApiService,
    required this.tmdbMovieService,
    required this.memberId,
  });

  final RatingApiService ratingApiService;
  final TmdbMovieService tmdbMovieService;
  final int memberId;

  MyRatingsState state = MyRatingsState.idle;

  List<RatingWithMovie> ratings = [];

  String? errorMessage;
  String? refreshWarning;

  Future<void> loadRatings() async {
    state = MyRatingsState.loading;
    errorMessage = null;
    refreshWarning = null;
    notifyListeners();

    try {
      final ratingDtos =
          await ratingApiService.fetchRatingsByMember(
        memberId,
      );

      if (ratingDtos.isEmpty) {
        ratings = [];
        state = MyRatingsState.empty;
        notifyListeners();
        return;
      }

      final result = <RatingWithMovie>[];

      for (final rating in ratingDtos) {
        final movie =
            await tmdbMovieService.fetchMovieDetail(
          rating.movieId,
        );

        result.add(
          RatingWithMovie(
            rating: rating,
            movie: movie,
          ),
        );
      }

      ratings = result;
      state = MyRatingsState.success;
    } catch (e) {
      ratings = [];
      errorMessage = e.toString();
      state = MyRatingsState.error;
    }

    notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    await loadRatings();

    if (state == MyRatingsState.error) {
      refreshWarning =
          '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    } else {
      refreshWarning = null;
    }

    notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await ratingApiService.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      errorMessage = writeErrorMessage(error);
      notifyListeners();

      if (shouldRefreshAfterRatingError(error)) {
        await loadRatings();
      }

      rethrow;
    }

    await _refreshAfterWrite();
  }

  Future<void> deleteRating(
    int ratingId,
  ) async {
    try {
      await ratingApiService.deleteRating(
        memberId: memberId,
        ratingId: ratingId,
      );
    } on DioException catch (error) {
      errorMessage = writeErrorMessage(error);
      notifyListeners();

      if (shouldRefreshAfterRatingError(error)) {
        await loadRatings();
      }

      rethrow;
    }

    await _refreshAfterWrite();
  }
}