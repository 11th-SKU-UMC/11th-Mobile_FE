import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 6주차 MemberCheckService의 이름을 바꾸고 회원가입 POST를 추가했습니다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 성공은 직접 객체 `{ "available": true }`, 오류는 v6 공통 형식입니다.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 201 + 공통 응답. result에서 회원가입 payload를 읽습니다.
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

/// 400·409 모두 서버 message가 사용자에게 보여줄 수 있는 문장이므로 그대로 씁니다.
String writeSignUpErrorMessage(DioException error) {
  return tryParseCommonError(error)?.message ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
