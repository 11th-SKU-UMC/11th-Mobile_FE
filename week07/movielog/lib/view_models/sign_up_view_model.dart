import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인 상태를 관리합니다.
/// 두 입력란의 상태·요청 버전은 서로 영향을 주지 않도록 필드별로 분리합니다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;

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
    _clearSubmitError();
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
    _clearSubmitError();
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

  // ───────────────────────── 가입 제출 ─────────────────────────
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId; // 가입 성공 응답에서 읽은 실제 ID입니다.
  String? passwordErrorText; // 비밀번호 입력칸에 붙이는 서버 오류(400)
  String? snackbarMessage; // 어느 입력칸에도 붙지 않는 서버 오류(그 외 400, 409 등)

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  /// 닉네임·이메일 중복 확인이 모두 통과해야 가입할 수 있습니다.
  bool get isChecksPassed =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void onPasswordChanged() {
    passwordErrorText = null;
    _clearSubmitError();
    if (!_disposed) notifyListeners();
  }

  // 입력이 바뀌면 이전 서버 오류를 함께 무효화합니다.
  void _clearSubmitError() {
    snackbarMessage = null;
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      // 400 중 메시지에 '비밀번호'가 명시된 경우만 입력칸에, 나머지는 Snackbar로 보냅니다.
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } catch (_) {
      // StateError뿐 아니라 응답 형식 오류에서도 submitting 상태에 머물지 않게 합니다.
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
