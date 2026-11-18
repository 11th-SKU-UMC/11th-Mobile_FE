import 'package:dio/dio.dart';

import '../models/login_models.dart';
import 'api_error.dart';

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post(
      '/v7/auth/login',
      data: request.toJson(),
      options: Options(followRedirects: false),
    );
    final result = requireResult(response, 200, LoginResult.fromJson);
    if (result.accessToken.trim().isEmpty) {
      throw const ApiException('로그인 응답에 인증 정보가 없습니다.');
    }
    return result;
  }
}
