class UpdateMemberRequest {
  const UpdateMemberRequest({
    required this.nickname,
  });

  final String nickname;

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
    };
  }
}