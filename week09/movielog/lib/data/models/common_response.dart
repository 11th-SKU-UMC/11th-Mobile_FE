/// v6 공통 응답 형식. `{ isSuccess, code, message, result }`
///
/// 회원가입·평점 등록·평점 수정의 성공 응답과 v6의 모든 실패 응답이 이 형식이다.
/// `result`는 API마다 담기는 값이 달라서 제네릭 [T]로 두고, 없거나 실패면 null이다.
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

  /// 오류 응답 body를 공통 형식으로 읽는다. 형식이 다르면(프록시 HTML, v5 형식 등) null.
  ///
  /// 오류 처리 중에 다시 파싱 예외가 나지 않도록 실패를 삼킨다.
  static CommonResponse<Object?>? tryParseError(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    try {
      return CommonResponse<Object?>.fromJson(data, (value) => value);
    } on TypeError {
      return null;
    }
  }
}
