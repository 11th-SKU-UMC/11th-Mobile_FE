import 'package:dio/dio.dart';

import '../models/common_response.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

CommonResponse<Object?>? commonError(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  try {
    return CommonResponse<Object?>.fromJson(data, (value) => value);
  } catch (_) {
    return null;
  }
}

String? apiErrorCode(Object error) => switch (error) {
  ApiException() => error.code,
  DioException() => switch (error.response?.data) {
    {'code': final String code} => code,
    _ => null,
  },
  _ => null,
};

int? apiStatusCode(Object error) => switch (error) {
  DioException() => error.response?.statusCode,
  ApiException() => error.statusCode,
  _ => null,
};

bool isExpiredSession(Object error) =>
    apiStatusCode(error) == 401 &&
    const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(apiErrorCode(error));

String apiErrorMessage(
  Object error, {
  String fallback = '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  if (error is ApiException) return error.message;
  final message = commonError(error)?.message;
  return message == null || message.trim().isEmpty ? fallback : message;
}

Object? requireWriteResponse(Response<dynamic> response, int expectedStatus) {
  final data = response.data;
  if (response.statusCode != expectedStatus || data is! Map<String, dynamic>) {
    throw const ApiException('서버 응답을 확인하지 못했습니다.');
  }
  final common = CommonResponse<Object?>.fromJson(data, (value) => value);
  if (!common.isSuccess) {
    throw ApiException(
      common.message,
      code: common.code,
      statusCode: response.statusCode,
    );
  }
  return common.result;
}

T requireResult<T>(
  Response<dynamic> response,
  int expectedStatus,
  T Function(Map<String, dynamic>) parse,
) {
  final result = requireWriteResponse(response, expectedStatus);
  if (result is! Map<String, dynamic>) {
    throw const ApiException('서버 응답 형식이 올바르지 않습니다.');
  }
  return parse(result);
}

String ratingErrorMessage(Object error) => switch (apiErrorCode(error)) {
  'RATING403_1' => '본인이 작성한 평점만 변경할 수 있습니다.',
  'RATING404_1' => '이미 삭제되었거나 존재하지 않는 평점입니다.',
  'RATING409_1' => '이 영화에 이미 평점을 남겼습니다.',
  _ => apiErrorMessage(error, fallback: '평점을 저장하지 못했습니다. 다시 시도해 주세요.'),
};
