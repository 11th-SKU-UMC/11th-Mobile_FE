import 'package:dio/dio.dart';

import '../../core/storage/secure_token_storage.dart';
import '../models/common_response.dart';
import '../models/login_request.dart';
import '../models/login_result.dart';

class AuthApiService {
  const AuthApiService(this._dio);

  final Dio _dio;

  Future<CommonResponse<LoginResult>> login(
    LoginRequest request,
  ) async {
    final response = await _dio.post(
      '/v7/auth/login',
      data: request.toJson(),
    );

    final commonResponse =
        CommonResponse<LoginResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => LoginResult.fromJson(
        value as Map<String, dynamic>,
      ),
    );

    final result = commonResponse.result;

    if (commonResponse.isSuccess &&
        result != null) {
      await SecureTokenStorage.saveAccessToken(
        result.accessToken,
      );
    }

    return commonResponse;
  }
}