import 'package:dio/dio.dart';

import '../models/member_check_response.dart';

import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  const SignUpService(this._dio);

  final Dio _dio;

  Future<MemberCheckResponse> checkNickname(
    String nickname,
  ) async {
    final response = await _dio.get(
      '/v6/members/nickname/${Uri.encodeComponent(nickname)}',
    );

    return MemberCheckResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MemberCheckResponse> checkEmail(
    String email,
  ) async {
    final response = await _dio.get(
      '/v6/members/email/${Uri.encodeComponent(email)}',
    );

    return MemberCheckResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post(
      '/v6/members',
      data: request.toJson(),
    );

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(
        value as Map<String, dynamic>,
      ),
    );
  }
}

String writeSignUpErrorMessage(DioException error) {
  final data = error.response?.data;

  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(
          data,
          (value) => value,
        )
      : null;

  return common?.message ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}