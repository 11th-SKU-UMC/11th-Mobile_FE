import 'package:dio/dio.dart';

/// v6 공통 응답 형식입니다. 신규 쓰기 API의 성공 응답과 모든 v6 오류 응답을 감쌉니다.
class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;

  /// API마다 담기는 값이 다르므로 제네릭으로 표현합니다. 값이 없거나 실패면 null입니다.
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }
}

/// 오류 응답 body를 공통 형식으로 읽습니다. 통신 실패처럼 body가 없거나
/// 형식이 다르면 null을 반환해 호출부가 기본 문구를 쓰게 합니다.
CommonResponse<Object?>? tryParseCommonError(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  try {
    return CommonResponse<Object?>.fromJson(data, (value) => value);
  } on TypeError {
    return null;
  }
}
