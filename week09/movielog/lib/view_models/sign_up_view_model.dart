import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/sign_up_validation.dart';
import '../data/models/create_member_request.dart';
import '../data/services/api_error.dart';
import '../data/services/sign_up_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;
  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  bool canSubmit(CreateMemberRequest request) =>
      !_disposed &&
      !isSubmitting &&
      submitStatus != SubmitStatus.success &&
      request.nickname.trim() == _currentNickname &&
      request.email.trim() == _currentEmail &&
      validateNickname(request.nickname) == null &&
      validateEmail(request.email) == null &&
      validatePasswordFormat(request.password) == null &&
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void _clearSubmitError() {
    passwordErrorText = null;
    snackbarMessage = null;
    submitStatus = SubmitStatus.idle;
  }

  void onPasswordChanged() {
    if (_disposed || isSubmitting) return;
    _clearSubmitError();
    notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (!canSubmit(request)) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null || id < 1) throw StateError('Missing memberId');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = apiErrorMessage(
        error,
        fallback: error is DioException
            ? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.'
            : '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.',
      );
      if (apiStatusCode(error) == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    }
    if (!_disposed) notifyListeners();
  }

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? emailErrorText;
  String? _duplicatedNickname;
  String? _duplicatedEmail;
  String _currentNickname = '';
  String _currentEmail = '';
  int _nicknameRequestVersion = 0;
  int _emailRequestVersion = 0;
  bool _disposed = false;

  bool get canCheckNickname =>
      !_disposed &&
      !isSubmitting &&
      validateNickname(_currentNickname) == null &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      !_disposed &&
      !isSubmitting &&
      validateEmail(_currentEmail) == null &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    if (_disposed || isSubmitting) return;
    _clearSubmitError();
    _currentNickname = value.trim();
    _nicknameRequestVersion++;
    if (_currentNickname == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    notifyListeners();
  }

  void onEmailChanged(String value) {
    if (_disposed || isSubmitting) return;
    _clearSubmitError();
    _currentEmail = value.trim();
    _emailRequestVersion++;
    if (_currentEmail == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (!canCheckNickname || requested != _currentNickname) return;

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
      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';
      if (!available) _duplicatedNickname = requested;
    } catch (error) {
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = apiErrorMessage(
        error,
        fallback: '중복 확인에 실패했습니다. 다시 시도해 주세요.',
      );
    }
    if (!_disposed && version == _nicknameRequestVersion) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (!canCheckEmail || requested != _currentEmail) return;

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
      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } catch (error) {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus = CheckStatus.error;
      emailErrorText = apiErrorMessage(
        error,
        fallback: '중복 확인에 실패했습니다. 다시 시도해 주세요.',
      );
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
