import 'tmdb_movie_dto.dart';
import '../../models/rating_dto.dart';

class RatingWithMovie {
  const RatingWithMovie({
    required this.rating,
    required this.movie,
  });

  final RatingDto rating;
  final TmdbMovieDto movie;
}