import 'package:dio/dio.dart';

/// 서버 오류 응답 body의 code를 꺼냅니다. (예: AUTH401_2, RATING403_1)
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 서버 오류 응답 body의 message를 꺼냅니다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없거나(2)/무효(3)/만료(4)된 경우입니다.
/// 로그인 입력 오류인 AUTH401_1은 여기에 포함하지 않습니다.
bool isSessionExpiredCode(String? code) {
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
