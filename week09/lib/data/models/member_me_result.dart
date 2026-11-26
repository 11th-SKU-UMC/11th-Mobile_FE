class MemberMeResult {
  const MemberMeResult({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String email;
  final String nickname;
  final String createdAt;

  factory MemberMeResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return MemberMeResult(
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}