/// 즐겨찾기 등록·목록 응답의 항목입니다. 제목·포스터는 없으므로 movieId로 TMDB에서 보충합니다.
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

  /// TMDB 영화 ID입니다. 즐겨찾기 여부 조회·해제 경로에는 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final DateTime createdAt;
}
