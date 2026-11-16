import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  /// v5는 공통 Wrapper가 없으므로 응답 body가 곧 평점 배열입니다.
  /// 평점이 없는 회원은 빈 배열(실패 아님)이 내려옵니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
