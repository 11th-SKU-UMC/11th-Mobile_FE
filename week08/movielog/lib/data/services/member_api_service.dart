import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 API. 보호 Client(AuthInterceptor)를 쓴다.
class MemberApiService {
  MemberApiService(this._authDio);

  final Dio _authDio;

  /// `GET /v7/members/me`
  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// `PATCH /v7/members/me`. 중복이면 409 MEMBER409_1, 형식 오류면 400 COMMON400.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
