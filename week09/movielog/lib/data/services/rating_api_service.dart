import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 평점 API (v8).
/// - 유저별 조회: 공개 API → publicDio (토큰 없음, memberId path 유지)
/// - 등록·수정·삭제: 보호 API → authDio (Interceptor가 Authorization: Bearer 를 붙임)
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio;
  final Dio _authDio;

  /// 공개 조회: wrapper 없이 body가 곧 배열입니다. (8주차 기본 실습에서는 호출하지 않습니다.)
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v8/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  /// 등록: 사용자 식별은 토큰으로 합니다. body·path·query에 memberId를 넣지 않습니다.
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v8/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// PATCH는 부분 수정이 아니라 전체 교체입니다.
  /// comment를 생략하면 null로 전달되어 기존 후기가 지워지므로 score·comment를 항상 함께 보냅니다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v8/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// 삭제 성공은 204가 아니라 result가 null인 200 응답입니다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v8/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// 평점 쓰기 오류 → 사용자 안내 문구. 401(만료)은 호출한 ViewModel이 세션 정리를 담당합니다.
String writeErrorMessage(DioException error) {
  final code = apiErrorCode(error);
  switch (code) {
    case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
      return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    case 'RATING403_1':
      return '본인이 작성한 평점만 변경할 수 있어요.'; // 403: 권한 부족, 로그아웃하지 않음
    case 'RATING409_1':
      return '이미 이 영화에 평점을 남겼어요. 기존 기록을 확인해 주세요.';
    case 'RATING404_1':
      return '존재하지 않는 평점이에요.';
    case 'MEMBER404_1':
      return '존재하지 않는 회원이에요.';
    case 'COMMON400':
      return apiErrorMessage(error) ?? '입력값을 확인해 주세요.';
  }
  return apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 화면에 남은 목록이 서버와 어긋났다는 뜻(이미 삭제된 평점)이면 로컬 목록에서도 제거합니다.
bool isRatingNotFound(DioException error) => apiErrorCode(error) == 'RATING404_1';
