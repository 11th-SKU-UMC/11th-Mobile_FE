/// `POST /v8/auth/login` 요청 body.
///
/// 비밀번호는 저장하거나 출력하지 않는다. toString도 정의하지 않는다.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  /// 비밀번호는 입력한 그대로가 의미 있으므로 trim하지 않는다.
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

/// 로그인 성공 result. v7 계약상 memberId는 없다. (JWT claim도 추정하지 않는다)
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}
