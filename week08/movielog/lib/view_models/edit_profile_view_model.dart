import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 닉네임 수정입니다. 입력칸 문제는 [nicknameError], 입력과 무관한 문제는 [message]로 나눕니다.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;

  /// 입력 필드 아래에 보여줄 오류(길이, 중복)입니다.
  String? nicknameError;

  /// Snackbar로 보여줄 오류(네트워크 등)입니다.
  String? message;

  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  /// 서버에 보내기 전에 확인할 수 있는 규칙은 먼저 검사해 불필요한 통신을 줄입니다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 입력이 바뀌면 이전 서버 오류를 지웁니다.
  void onNicknameChanged() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지
    final version = _auth.sessionVersion;
    final current = _auth.member;
    if (_disposed || !_auth.isSignedIn || current == null) return false;

    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;
    if (nicknameError != null) {
      _notify();
      return false;
    }

    // 자기 자신의 현재 닉네임은 409가 아니지만, 바뀐 게 없으니 요청 없이 완료합니다.
    if (nickname == current.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
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
      status = EditProfileStatus.failure;
      final code = apiErrorCode(error);
      if (sessionExpiredCodes.contains(code)) {
        // 안내와 이동은 로그인 화면과 Router가 처리합니다.
        await _auth.expireSession();
        return false;
      }
      switch (code) {
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지합니다.
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃하지 않습니다.
      }
    } catch (_) {
      if (_isStale(version)) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  bool _isStale(int version) =>
      _disposed || version != _auth.sessionVersion || !_auth.isSignedIn;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
