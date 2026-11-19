import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 조회·수정은 보호 API이므로 Interceptor가 등록된 Client를 받습니다.
class MemberApiService {
  MemberApiService(this._authDio);

  final Dio _authDio;

  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// 수정 가능한 항목은 닉네임뿐입니다. 응답은 최신 내 정보입니다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
