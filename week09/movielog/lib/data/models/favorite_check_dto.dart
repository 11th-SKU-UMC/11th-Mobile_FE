/// `GET /v8/favorites/{movieId}` result. `{ "isFavorite": true }`
///
/// 응답에 movieId가 없어서 요청에 쓴 [movieId]를 fromJson에 따로 넘긴다.
class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});

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
