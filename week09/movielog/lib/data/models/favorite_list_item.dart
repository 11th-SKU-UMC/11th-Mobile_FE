import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

// 목록 카드 1장 = MovieLog 즐겨찾기 정보 + TMDB 영화 정보(실패하면 null)
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
  });

  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
  final String? errorMessage;

  bool get hasMovie => movie != null;
}
