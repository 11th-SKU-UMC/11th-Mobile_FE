import 'common_response.dart';

/// `GET/PATCH /v7/members/me`의 result입니다. memberId와 password는 내려오지 않습니다.
class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String email;
  final String nickname;
  final DateTime createdAt;

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// "2026.10.10 가입" 형식입니다.
  String get joinedLabel {
    final local = createdAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)} 가입';
  }
}

MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('내 정보 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
  final member = common.result;
  if (member == null) throw StateError('내 정보 result가 없습니다.');
  return member;
}
