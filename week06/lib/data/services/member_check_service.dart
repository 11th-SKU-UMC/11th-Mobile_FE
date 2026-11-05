import 'package:dio/dio.dart';

import '../models/member_check_response.dart';

class MemberCheckService {
  const MemberCheckService(this._dio);

  final Dio _dio;

  Future<MemberCheckResponse> checkNickname(
    String nickname,
  ) async {
    final response = await _dio.get(
      '/v5/members/nickname/${Uri.encodeComponent(nickname)}',
    );

    return MemberCheckResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MemberCheckResponse> checkEmail(
    String email,
  ) async {
    final response = await _dio.get(
      '/v5/members/email/${Uri.encodeComponent(email)}',
    );

    return MemberCheckResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}