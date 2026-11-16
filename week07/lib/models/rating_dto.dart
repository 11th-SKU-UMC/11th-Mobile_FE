class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final int ratingId;
  final int movieId;
  final int score;
  final String? comment;
  final String createdAt;
  final String updatedAt;

  factory RatingDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return RatingDto(
      ratingId: (json['ratingId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}