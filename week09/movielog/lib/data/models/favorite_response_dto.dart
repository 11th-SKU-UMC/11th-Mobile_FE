/// `POST /v8/favorites` result, `GET /v8/favorites` result 배열의 한 항목.
///
/// 제목·포스터는 없다. 화면에 보여줄 정보는 [movieId]로 TMDB에서 보충한다.
class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  factory FavoriteResponseDto.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('FavoriteResponseDto must be a JSON object.');
    }
    return FavoriteResponseDto(
      favoriteId: (json['favoriteId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int favoriteId;

  /// TMDB 영화 id.
  final int movieId;
  final DateTime createdAt;
}
