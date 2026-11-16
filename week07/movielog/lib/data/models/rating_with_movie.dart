import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

/// 자체 백엔드의 평점 한 건과, 그 movieId로 TMDB에서 찾은 영화 정보를 묶은 것.
///
/// 평점의 주인은 자체 백엔드이므로 [movie]를 찾지 못해도 평점은 남긴다.
class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});

  final RatingDto rating;

  /// TMDB에서 찾지 못했거나 조회에 실패했으면 null. 화면은 placeholder를 그린다.
  final TmdbMovieDto? movie;
}
