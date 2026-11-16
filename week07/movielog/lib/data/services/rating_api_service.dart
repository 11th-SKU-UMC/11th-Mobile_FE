import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import 'api_error.dart';

class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // The documented result may be a ratingId or null. Do not assume its type.
    requireWriteResponse(response, 201);
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final response = await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      // PATCH requires score; null explicitly clears the old comment.
      data: {'score': score, 'comment': normalizeComment(comment)},
    );
    requireWriteResponse(response, 200);
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw const ApiException('삭제 결과를 확인하지 못했습니다. 목록을 다시 조회해 주세요.');
    }
    // HTTP 204 has no response body.
  }
}

String writeMyRatingsErrorMessage(Object error) => apiErrorMessage(
  error,
  fallback: switch (apiStatusCode(error)) {
    400 => 'memberId 형식을 다시 확인해 주세요.',
    404 => '존재하지 않는 회원입니다.',
    _ => '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
  },
);
