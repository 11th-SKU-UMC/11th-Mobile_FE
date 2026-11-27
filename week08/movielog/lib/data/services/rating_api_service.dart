import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

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

/// v7 평점 API.
///
/// - 유저별 조회 `GET /v7/members/{memberId}/ratings`: 공개 Client, 200 + 직접 배열
/// - 등록 `POST /v7/ratings`: 보호 Client, 201 + 공통 형식(result: Rating)
/// - 수정 `PATCH /v7/ratings/{ratingId}`: 보호 Client, 200 + 공통 형식(result: Rating)
/// - 삭제 `DELETE /v7/ratings/{ratingId}`: 보호 Client, 200 + 공통 형식(result: null)
///
/// 사용자 식별은 Authorization 헤더로만 한다. path·body·query에 memberId를 넣지 않는다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  /// 공개 조회. 토큰이 필요 없으므로 공개 Client로 보낸다.
  /// v7 로그인·내 정보에는 memberId가 없어 현재 앱 화면에서는 호출하지 않는다.
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// PATCH는 전체 교체다. comment를 생략하면 null로 덮이므로 score와 함께 항상 보낸다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// v6과 달리 성공은 204가 아니라 200(result null)이다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 쓰기 오류를 어떻게 처리할지.
enum RatingErrorAction {
  /// AUTH401_2/3/4: 세션을 정리하고 로그인 화면으로 보낸다.
  expireSession,

  /// RATING403_1·RATING409_1: Snackbar로 안내만 한다. 로그아웃하지 않는다.
  snackbar,

  /// RATING404_1: 이미 없는 평점이라는 안내를 보여주고 목록에서 뺀다.
  notFound,

  /// 그 외(400 별점 범위, 네트워크 등): Dialog 안에 문구를 보여주고 다시 시도하게 한다.
  inline,
}

RatingErrorAction ratingErrorAction(DioException error) {
  if (isSessionExpiredError(error)) return RatingErrorAction.expireSession;
  return switch (apiErrorCode(error)) {
    'RATING403_1' || 'RATING409_1' => RatingErrorAction.snackbar,
    'RATING404_1' => RatingErrorAction.notFound,
    _ => RatingErrorAction.inline,
  };
}

/// 평점 쓰기 실패 문구.
String writeErrorMessage(DioException error) {
  switch (apiErrorCode(error)) {
    case 'RATING403_1':
      return '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.';
    case 'RATING409_1':
      return '이미 이 영화에 평점을 남겼어요. 마이페이지에서 기존 기록을 확인해 주세요.';
    case 'RATING404_1':
      return '이미 삭제됐거나 존재하지 않는 평점이에요.';
  }
  if (error.response == null) {
    return '네트워크 상태를 확인하고 다시 시도해 주세요.';
  }
  return apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
