class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email.trim(), 'password': password};
}

/// v7 로그인 result입니다. memberId는 없습니다. (JWT claim도 추정하지 않습니다.)
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
