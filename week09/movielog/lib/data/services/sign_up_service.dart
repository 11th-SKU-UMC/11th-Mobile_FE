import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  SignUpService(this._dio);
  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>).available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>).available;
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
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 서버 오류 응답(400 비밀번호 형식, 409 중복 등)의 message를 그대로 꺼냅니다.
/// message에 사용자에게 보여줄 수 있는 문장이 이미 들어 있으므로 code별 문구를 새로 만들지 않습니다.
String writeSignUpErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
