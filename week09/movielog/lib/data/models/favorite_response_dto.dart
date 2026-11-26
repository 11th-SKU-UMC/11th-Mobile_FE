class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  final int favoriteId;
  final int movieId;
  final DateTime createdAt;

  factory FavoriteResponseDto.fromJson(Map<String, dynamic> json) =>
      FavoriteResponseDto(
        favoriteId: (json['favoriteId'] as num).toInt(),
        movieId: (json['movieId'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
