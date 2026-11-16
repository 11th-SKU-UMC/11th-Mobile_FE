import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// v6 평점 조회·등록·수정·삭제 API.
///
/// 응답 계약이 API마다 다르다.
/// - 조회 GET: 200 + 직접 배열
/// - 등록 POST: 201 + 공통 형식 (result는 계약이 확정되지 않아 파싱하지 않는다)
/// - 수정 PATCH: 200 + 공통 형식(result null)
/// - 삭제 DELETE: 204 + body 없음 (파싱하지 않는다)
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 없으면 빈 배열이 온다. (실패가 아니다)
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
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// comment를 생략하면 서버가 기존 후기를 null로 덮으므로 score와 함께 항상 보낸다.
  /// (null을 보내면 후기 삭제 의도)
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

  /// 204는 body가 없으므로 response.data를 읽지 않는다.
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

/// 평점 조회(GET) 실패를 상태 코드별 사용자 문구로 바꾼다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 쓰기(등록·수정·삭제) 실패 문구. 같은 COMMON404라도 등록은 '유저',
/// 수정·삭제는 '평점'을 가리키므로 code로 문구를 만들지 않고 서버 message를 쓴다.
String writeErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 403(본인 평점 아님)·404(평점 없음)는 화면 목록이 서버와 어긋났다는 뜻이라 다시 조회한다.
/// 400(별점 범위)·409(중복 등록)는 값만 고쳐 다시 시도하면 되므로 조회하지 않는다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = CommonResponse.tryParseError(error.response?.data)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}
