import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 200 + 직접 배열입니다. (v5부터 있던 조회 API라 성공 응답은 wrapper가 없습니다.)
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 201 + wrapper. result의 숫자/null 계약이 확정되지 않았으므로 파싱하지 않고,
  /// 성공 후 GET으로 목록을 다시 확인합니다.
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// 200 + result null. comment를 생략하면 기존 후기가 null로 덮이므로
  /// 유지하려면 호출부가 기존 값을 명시적으로 보냅니다.
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
  }

  /// 204 + body 없음. 응답을 JSON으로 파싱하지 않습니다.
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 빈 배열(Empty)과 400·404·통신 실패(Error)를 구분해 안내합니다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 같은 COMMON404라도 등록은 "유저", 수정·삭제는 "평점"을 가리키므로
/// code로 문구를 새로 만들지 않고 서버 message를 그대로 보여줍니다.
String writeErrorMessage(DioException error) {
  return tryParseCommonError(error)?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// code는 문구가 아니라 다음 UI 행동(다시 조회할지)을 결정하는 데만 씁니다.
/// 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = tryParseCommonError(error)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}
