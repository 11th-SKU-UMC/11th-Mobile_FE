import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// v5 닉네임·이메일 중복 확인 API.
///
/// 결과(available)만 돌려주고, 상태 전환과 문구는 ViewModel이 정한다.
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(
      response.data as Map<String, dynamic>,
    ).available;
  }

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(
      response.data as Map<String, dynamic>,
    ).available;
  }
}
