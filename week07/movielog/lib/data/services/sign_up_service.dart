import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// v6 회원가입 API와 닉네임·이메일 중복 확인 API. (6주차 MemberCheckService)
///
/// 중복 확인 GET은 성공 시 직접 객체를 주고, 오류만 공통 형식이다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(
      response.data as Map<String, dynamic>,
    ).available;
  }

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(
      response.data as Map<String, dynamic>,
    ).available;
  }

  /// `POST /v6/members`. 성공은 201 + 공통 형식(result: SignUpResult).
  /// 400(입력 형식)·409(이메일/닉네임 중복)는 DioException으로 던진다.
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 회원가입 오류의 서버 message를 그대로 쓴다. 공통 형식이 아니면 기본 문구.
String writeSignUpErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
