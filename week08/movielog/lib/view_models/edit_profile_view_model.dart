import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필(닉네임) 수정 화면의 상태.
///
/// - 입력칸 문제(길이·중복·형식)는 [nicknameError]로 필드 아래에, 입력과 무관한 문제
///   (네트워크 등)는 [message]로 Snackbar에 보여준다. 어느 경우든 입력값은 화면이 유지한다.
/// - 네트워크 실패로는 로그아웃하지 않는다. AUTH401_2/3/4만 세션을 정리한다.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  static const int minLength = 2;
  static const int maxLength = 12;
  static const String lengthErrorMessage = '닉네임은 2~12자로 입력해 주세요.';
  static const String duplicatedMessage = '이미 사용 중인 닉네임이에요.';
  static const String formatErrorMessage = '닉네임 형식을 확인해 주세요.';
  static const String memberNotFoundMessage = '회원 정보를 찾을 수 없어요.';
  static const String networkErrorMessage = '네트워크 상태를 확인하고 다시 시도해 주세요.';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했어요.';

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  /// 서버에 보내기 전에 확인할 수 있는 규칙(2~12자)은 먼저 검사한다.
  String? validateNickname(String value) {
    final length = value.trim().length;
    if (length < minLength || length > maxLength) return lengthErrorMessage;
    return null;
  }

  /// 입력을 고치면 이전 오류를 지운다.
  void onNicknameChanged() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  /// 성공(또는 변경 없음)이면 true.
  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        _auth.member == null) {
      return false;
    }
    final version = _auth.sessionVersion;
    final nickname = input.trim();

    message = null;
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      status = EditProfileStatus.failure;
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료로 처리한다. (자기 닉네임은 409가 아니다)
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    bool isStale() =>
        _disposed ||
        version != _auth.sessionVersion ||
        _auth.status != AuthStatus.signedIn;

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (isStale()) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여준다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (isStale()) return false;
      debugPrint('닉네임 수정 실패: ${error.type} ${error.response?.statusCode}');
      status = EditProfileStatus.failure;
      if (isSessionExpiredError(error)) {
        // 안내와 이동은 로그인 화면과 Router가 맡는다.
        _notify();
        await _auth.expireSession();
        return false;
      }
      switch (apiErrorCode(error)) {
        case 'MEMBER409_1':
          nicknameError = duplicatedMessage; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? formatErrorMessage;
        case 'MEMBER404_1':
          message = memberNotFoundMessage;
        default:
          message = networkErrorMessage; // 로그아웃하지 않음
      }
    } catch (error) {
      if (isStale()) return false;
      debugPrint('닉네임 수정 처리 실패: ${error.runtimeType}');
      status = EditProfileStatus.failure;
      message = unknownErrorMessage;
    }
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
