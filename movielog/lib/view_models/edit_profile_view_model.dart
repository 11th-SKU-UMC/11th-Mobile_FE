import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError; // 입력 필드 아래에 보여줄 오류 (길이·중복)
  String? message; // Snackbar로 보여줄 오류 (네트워크 등)
  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  // 서버에 보내기 전에 확인할 수 있는 규칙은 클라이언트에서 먼저 검사합니다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  // 입력이 바뀌면 이전 오류를 지웁니다. (입력값 자체는 화면의 Controller가 유지)
  void onNicknameChanged() {
    if (nicknameError == null && message == null) return;
    nicknameError = null;
    message = null;
    _notify();
  }

  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지

    final version = _auth.sessionVersion;
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        _auth.member == null) {
      return false;
    }
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료로 처리합니다. (같은 값은 409가 아님)
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    nicknameError = null;
    message = null;
    _notify();

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (_isStale(version)) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여줍니다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (_isStale(version)) return false;
      final code = apiErrorCode(error);
      status = EditProfileStatus.failure;
      if (isSessionExpiredCode(code)) {
        // 세션 만료: 안내와 이동은 로그인 화면과 Router가 처리합니다.
        await _auth.expireSession();
        return false;
      }
      switch (code) {
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃하지 않음
      }
    } catch (_) {
      if (_isStale(version)) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  // 화면이 닫혔거나 로그아웃·계정 전환 뒤 도착한 응답은 반영하지 않습니다.
  bool _isStale(int version) =>
      _disposed ||
      version != _auth.sessionVersion ||
      _auth.status != AuthStatus.signedIn;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
