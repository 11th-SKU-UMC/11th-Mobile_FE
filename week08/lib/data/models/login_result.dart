class LoginResult {
  const LoginResult({
    required this.nickname,
    required this.accessToken,
  });

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}