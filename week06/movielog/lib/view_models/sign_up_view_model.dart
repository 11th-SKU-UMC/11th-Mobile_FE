import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인 상태를 관리합니다.
/// 두 입력란의 상태·요청 버전은 서로 영향을 주지 않도록 필드별로 분리합니다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;

  static const _checkFailedText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';

  bool _disposed = false;

  // ───────────────────────── 닉네임 ─────────────────────────
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicatedNickname; // 마지막으로 "중복"이었던 값
  String _currentNickname = '';
  int _nicknameRequestVersion = 0;

  bool get canCheckNickname =>
      _currentNickname.isNotEmpty &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    final trimmed = value.trim();
    _currentNickname = trimmed;
    _nicknameRequestVersion++; // 이전 요청의 응답을 무효화합니다.
    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      // 이전에 중복이었던 값을 다시 입력: API 재호출 없이 즉시 복원
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_nicknameRequestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(requested);
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }
      if (available) {
        nicknameCheckStatus = CheckStatus.available;
        nicknameErrorText = null;
      } else {
        // 서버가 정상 응답한 "중복" (통신 실패와 구분)
        nicknameCheckStatus = CheckStatus.duplicated;
        nicknameErrorText = '이미 사용 중인 닉네임입니다.';
        _duplicatedNickname = requested;
      }
    } on DioException {
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = _checkFailedText;
    } catch (_) {
      // 응답 형식이 예상과 다른 경우에도 checking 상태에 머물지 않게 합니다.
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = _checkFailedText;
    }
    if (!_disposed && version == _nicknameRequestVersion) notifyListeners();
  }

  // ───────────────────────── 이메일 ─────────────────────────
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail; // 마지막으로 "중복"이었던 값
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  bool get canCheckEmail =>
      _currentEmail.isNotEmpty &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  void onEmailChanged(String value) {
    final trimmed = value.trim();
    _currentEmail = trimmed;
    _emailRequestVersion++;
    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (requested.isEmpty ||
        requested != _currentEmail ||
        !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      if (available) {
        emailCheckStatus = CheckStatus.available;
        emailErrorText = null;
      } else {
        emailCheckStatus = CheckStatus.duplicated;
        emailErrorText = '이미 사용 중인 이메일입니다.';
        _duplicatedEmail = requested;
      }
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _checkFailedText;
    } catch (_) {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _checkFailedText;
    }
    if (!_disposed && version == _emailRequestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
