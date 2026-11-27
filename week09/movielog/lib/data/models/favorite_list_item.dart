import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

/// 내 즐겨찾기 화면의 카드 한 장. MovieLog 즐겨찾기 + TMDB 영화 정보.
///
/// TMDB 조회에 실패하면 [movie]가 null이고 [errorMessage]가 있다.
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
