class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});

  final int movieId;
  final bool isFavorite;

  factory FavoriteCheckDto.fromJson(
    Map<String, dynamic> json, {
    required int movieId,
  }) => FavoriteCheckDto(
    movieId: movieId,
    isFavorite: json['isFavorite'] as bool,
  );
}
