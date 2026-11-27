import 'package:dio/dio.dart';

// 서버 오류 body의 code를 꺼냅니다. (예: AUTH401_2, MEMBER409_1)
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

// 서버 오류 body의 message를 꺼냅니다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

// 보호 요청의 토큰 없음·무효·만료. 로그인 실패(AUTH401_1)는 포함하지 않습니다.
bool isSessionExpiredCode(String? code) =>
    code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';

bool isSessionExpiredError(Object error) =>
    error is DioException && isSessionExpiredCode(apiErrorCode(error));
