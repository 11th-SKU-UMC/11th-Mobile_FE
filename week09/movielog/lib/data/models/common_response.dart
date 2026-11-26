/// v6부터 쓰는 공통 응답 형식입니다. 쓰기·인증 API의 성공 응답과 오류 응답을 감쌉니다.
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
