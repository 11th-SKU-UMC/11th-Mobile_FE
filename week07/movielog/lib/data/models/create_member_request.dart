/// `POST /v6/members` 요청 body.
///
/// 비밀번호는 로그·저장소에 남기지 않는다. toString도 정의하지 않는다.
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  /// 비밀번호는 사용자가 입력한 문자 그대로가 의미 있으므로 trim하지 않는다.
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}
