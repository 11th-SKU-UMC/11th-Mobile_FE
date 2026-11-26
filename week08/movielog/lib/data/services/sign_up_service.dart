import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입·중복 확인은 토큰이 필요 없는 공개 API이므로 공개 Client를 받습니다.
/// 8주차에 v7 경로로 옮겼습니다. 계약(성공 형식, COMMON400/COMMON409)은 v6과 같습니다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 성공은 직접 객체 `{ "available": true }`, 오류는 v6 공통 형식입니다.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v7/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v7/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 201 + 공통 응답. result에서 회원가입 payload를 읽습니다.
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v7/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 400·409 모두 서버 message가 사용자에게 보여줄 수 있는 문장이므로 그대로 씁니다.
String writeSignUpErrorMessage(DioException error) {
  return apiErrorMessage(error) ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
