import 'package:dio/dio.dart';

import '../models/member_info.dart';
import 'api_error.dart';

class MemberApiService {
  MemberApiService(this._dio);
  final Dio _dio;

  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get('/v7/members/me');
    return requireResult(response, 200, MemberInfo.fromJson);
  }

  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _dio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return requireResult(response, 200, MemberInfo.fromJson);
  }
}
