import 'favorite_response_dto.dart';
import 'rating_dto.dart';

/// Challenge: `POST /v8/movie-records` 요청 body입니다. 평점과 즐겨찾기를 한 번에 저장합니다.
class CreateMovieRecordRequest {
  const CreateMovieRecordRequest({
    required this.movieId,
    required this.score,
    required this.addToFavorites,
    this.comment,
  });

  final int movieId;

  /// 1~5 정수입니다.
  final int score;
  final String? comment;

  /// 필수 boolean입니다. false면 응답의 favorite이 null인 것이 정상입니다.
  final bool addToFavorites;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
    'addToFavorites': addToFavorites,
  };
}

/// `POST /v8/movie-records`의 result입니다. rating과 favorite은 기존 DTO를 재사용합니다.
class MovieRecordResponseDto {
  const MovieRecordResponseDto({required this.rating, this.favorite});

  factory MovieRecordResponseDto.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'MovieRecordResponseDto must be a JSON object.',
      );
    }
    final favorite = json['favorite'];
    return MovieRecordResponseDto(
      rating: RatingDto.fromJson(json['rating'] as Map<String, dynamic>),
      favorite: favorite == null
          ? null
          : FavoriteResponseDto.fromJson(favorite),
    );
  }

  final RatingDto rating;
  final FavoriteResponseDto? favorite;
}
