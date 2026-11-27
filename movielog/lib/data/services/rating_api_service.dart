import 'package:dio/dio.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';

// v7 등록·수정 result는 Rating 객체입니다.
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

// 공개 유저별 평점 조회는 wrapper 없이 직접 배열입니다.
List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio; // 공개 조회: 토큰 없음
  final Dio _authDio; // 등록·수정·삭제: Interceptor가 Bearer 토큰을 붙임

  // 공개 API: memberId path를 유지합니다. (v7 로그인 응답에는 memberId가 없어
  // 현재는 토큰 기반 '내 평점 전체 조회'에 쓸 수 없습니다.)
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v8/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  // 등록: memberId는 path·body 어디에도 보내지 않습니다.
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v8/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  // PATCH는 전체 교체입니다. comment를 생략하면 기존 후기가 null로 덮입니다.
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

  // v7 삭제 성공: 200 + wrapper(result null). v6의 204가 아닙니다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v8/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

// 평점 쓰기 오류를 v7 도메인 code로 구분합니다.
String writeErrorMessage(DioException error) {
  final code = apiErrorCode(error);
  if (isSessionExpiredCode(code)) return '로그인이 만료됐어요. 다시 로그인해 주세요.';
  switch (code) {
    case 'RATING403_1':
      return '본인이 작성한 평점만 수정·삭제할 수 있어요.';
    case 'RATING404_1':
      return '해당 평점을 찾을 수 없어요. 목록을 새로고침했어요.';
    case 'RATING409_1':
      return '이미 이 영화에 평점을 남겼어요. 기존 기록을 확인해 주세요.';
    case 'MEMBER404_1':
      return '회원 정보를 찾을 수 없어요.';
    case 'COMMON400':
      return apiErrorMessage(error) ?? '입력값을 확인해 주세요.';
  }
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

// 404는 화면 목록이 서버와 어긋났다는 뜻이라 현재 목록에서 정리합니다.
bool isRatingNotFound(DioException error) =>
    apiErrorCode(error) == 'RATING404_1';
