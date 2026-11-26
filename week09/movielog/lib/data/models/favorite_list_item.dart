import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

/// 내 즐겨찾기 화면의 카드 한 장입니다.
/// MovieLog 즐겨찾기 정보와 TMDB 영화 정보를 movieId로 합친 결과입니다.
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
    this.isRetrying = false,
  });

  final FavoriteResponseDto favorite;

  /// TMDB 조회에 실패하면 null이며, 화면은 placeholder와 재조회 버튼을 보여 줍니다.
  final TmdbMovieDto? movie;
  final String? errorMessage;

  /// 이 카드만 TMDB 정보를 다시 조회하는 중인지 나타냅니다.
  final bool isRetrying;

  bool get hasMovie => movie != null;
}
