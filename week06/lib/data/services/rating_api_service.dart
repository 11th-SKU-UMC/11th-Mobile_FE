import 'package:dio/dio.dart';

import '../../models/rating_dto.dart';

class RatingApiService {
  const RatingApiService(this._dio);

  final Dio _dio;

  Future<List<RatingDto>> fetchRatingsByMember(
    int memberId,
  ) async {
    final response = await _dio.get(
      '/v5/members/$memberId/ratings',
    );

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) => RatingDto.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}