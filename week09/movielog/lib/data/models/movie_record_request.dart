import 'rating_request.dart';

class MovieRecordRequest {
  const MovieRecordRequest({
    required this.rating,
    required this.addToFavorites,
  });

  final CreateRatingRequest rating;
  final bool addToFavorites;

  Map<String, dynamic> toJson() => {
    ...rating.toJson(),
    'addToFavorites': addToFavorites,
  };
}
