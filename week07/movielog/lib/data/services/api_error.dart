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

int? apiStatusCode(Object error) => switch (error) {
  DioException() => error.response?.statusCode,
  ApiException() => error.statusCode,
  _ => null,
};

String apiErrorMessage(
  Object error, {
  String fallback = '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  if (error is ApiException) return error.message;
  final message = commonError(error)?.message;
  return message == null || message.trim().isEmpty ? fallback : message;
}

bool shouldRefreshAfterRatingError(Object error) {
  final code = error is ApiException ? error.code : commonError(error)?.code;
  final status = apiStatusCode(error);
  return code == 'COMMON403' ||
      code == 'COMMON404' ||
      status == 403 ||
      status == 404;
}

void requireWriteResponse(Response<dynamic> response, int expectedStatus) {
  if (response.statusCode != expectedStatus) {
    throw const ApiException('서버 처리 결과를 확인하지 못했습니다. 다시 요청하기 전에 목록을 조회해 주세요.');
  }
  final common = CommonResponse<Object?>.fromJson(
    response.data as Map<String, dynamic>,
    (value) => value,
  );
  if (!common.isSuccess) {
    throw ApiException(
      common.message,
      code: common.code,
      statusCode: response.statusCode,
    );
  }
}
