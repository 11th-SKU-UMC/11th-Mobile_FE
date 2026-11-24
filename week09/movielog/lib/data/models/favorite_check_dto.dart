class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});

  // 여부 조회 응답에는 movieId가 없으므로, 요청에 쓴 movieId를 따로 넘깁니다.
  factory FavoriteCheckDto.fromJson(Object? json, {required int movieId}) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('FavoriteCheckDto must be a JSON object.');
    }
    if (json['isFavorite'] is! bool) {
      throw const FormatException('isFavorite must be a boolean.');
    }
    return FavoriteCheckDto(
      movieId: movieId,
      isFavorite: json['isFavorite'] as bool,
    );
  }

  final int movieId;
  final bool isFavorite;
}
