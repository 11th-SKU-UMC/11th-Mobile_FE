import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/member_me_result.dart';

import '../models/update_member_request.dart';

class MemberApiService {
  const MemberApiService(this._dio);

  final Dio _dio;

  Future<CommonResponse<MemberMeResult>>
      getMyInfo() async {
    final response = await _dio.get(
      '/v7/members/me',
    );

    return CommonResponse<MemberMeResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => MemberMeResult.fromJson(
        value as Map<String, dynamic>,
      ),
    );
  }

  Future<CommonResponse<MemberMeResult>> updateMyInfo(
    UpdateMemberRequest request,
  ) async {
    final response = await _dio.patch(
        '/v7/members/me',
        data: request.toJson(),
    );

    return CommonResponse<MemberMeResult>.fromJson(
        response.data as Map<String, dynamic>,
        (value) => MemberMeResult.fromJson(
        value as Map<String, dynamic>,
        ),
    );
  }
}