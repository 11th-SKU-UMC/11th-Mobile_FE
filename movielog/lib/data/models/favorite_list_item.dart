import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';

// 내 즐겨찾기 카드 1개 = MovieLog 즐겨찾기 + (movieId로 찾은) TMDB 영화 정보
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
  });

  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie; // 조회 실패 시 null → placeholder 카드
  final String? errorMessage;

  bool get hasMovie => movie != null;
}
