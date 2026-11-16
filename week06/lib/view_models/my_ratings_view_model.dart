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
  });

  final RatingApiService ratingApiService;
  final TmdbMovieService tmdbMovieService;

  MyRatingsState state = MyRatingsState.idle;

  List<RatingWithMovie> ratings = [];

  String? errorMessage;

  Future<void> loadRatings() async {
    state = MyRatingsState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      const memberId = 1;

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
}