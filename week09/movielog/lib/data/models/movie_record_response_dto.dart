import 'favorite_response_dto.dart';
import 'rating_dto.dart';

class MovieRecordResponseDto {
  const MovieRecordResponseDto({required this.rating, this.favorite});

  final RatingDto rating;
  final FavoriteResponseDto? favorite;

  factory MovieRecordResponseDto.fromJson(Map<String, dynamic> json) {
    final favorite = json['favorite'] as Map<String, dynamic>?;
    return MovieRecordResponseDto(
      rating: RatingDto.fromJson(json['rating'] as Map<String, dynamic>),
      favorite: favorite == null
          ? null
          : FavoriteResponseDto.fromJson(favorite),
    );
  }
}
