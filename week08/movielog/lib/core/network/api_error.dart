import 'package:dio/dio.dart';

/// 서버 공통 오류 응답의 code를 꺼냅니다. 통신 실패처럼 body가 없으면 null입니다.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 서버 공통 오류 응답의 message를 꺼냅니다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없거나(2)·무효하거나(3)·만료된(4) 경우입니다.
/// 로그인 입력 오류인 AUTH401_1은 포함하지 않습니다.
const sessionExpiredCodes = {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'};

bool isSessionExpiredError(DioException error) =>
    sessionExpiredCodes.contains(apiErrorCode(error));

const sessionExpiredMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';

/// 화면에 보여줄 문구입니다. 서버 message가 있으면 그대로 쓰고, 없으면 [fallback]을 씁니다.
String describeApiError(
  DioException error, {
  String fallback = '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  if (isSessionExpiredError(error)) return sessionExpiredMessage;
  return apiErrorMessage(error) ?? fallback;
}
