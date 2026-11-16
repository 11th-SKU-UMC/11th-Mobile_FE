import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

/// v5 유저별 평점 조회 API.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 없으면 빈 배열이 온다. (실패가 아니다)
  /// memberId 형식이 잘못되면 400, 없는 회원이면 404로 DioException이 난다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// 평점 조회 실패를 상태 코드별 사용자 문구로 바꾼다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
