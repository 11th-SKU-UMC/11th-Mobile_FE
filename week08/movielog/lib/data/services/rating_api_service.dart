import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import 'api_error.dart';

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get<List<dynamic>>(
      '/v7/members/$memberId/ratings',
    );
    final list = response.data;
    if (list == null) throw const ApiException('평점 목록 응답이 비어 있습니다.');
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return requireResult(response, 201, RatingDto.fromJson);
  }

  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': normalizeComment(comment)},
    );
    return requireResult(response, 200, RatingDto.fromJson);
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    final result = requireWriteResponse(response, 200);
    if (result != null) throw const ApiException('삭제 응답 형식이 올바르지 않습니다.');
  }
}
