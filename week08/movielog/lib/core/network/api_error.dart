import 'package:dio/dio.dart';

/// 오류 응답 body의 `code`(예: AUTH401_2, RATING409_1). 공통 형식이 아니면 null.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 오류 응답 body의 `message`. 공통 형식이 아니면 null.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청의 토큰 없음·무효·만료. 로그인 실패(AUTH401_1)는 포함하지 않는다.
bool isSessionExpiredError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
