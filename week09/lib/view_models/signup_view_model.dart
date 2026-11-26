import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';

enum CheckState {
  idle,
  loading,
  available,
  unavailable,
  error,
}

enum SubmitStatus {
  idle,
  submitting,
  success,
  error,
}

class SignupViewModel extends ChangeNotifier {
  SignupViewModel(this._service);

  final SignUpService _service;

  CheckState nicknameState = CheckState.idle;
  CheckState emailState = CheckState.idle;

  String _checkedNickname = '';
  String _checkedEmail = '';
  String _duplicatedNickname = '';

  SubmitStatus submitStatus = SubmitStatus.idle;

  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;

  Future<void> checkNickname(String nickname) async {
    if (nickname.trim().isEmpty) {
      nicknameState = CheckState.idle;
      notifyListeners();
      return;
    }

    nicknameState = CheckState.loading;
    notifyListeners();

    try {
      final result = await _service.checkNickname(
        nickname.trim(),
      );

      _checkedNickname = nickname.trim();

      if (result.available) {
        nicknameState = CheckState.available;
      } else {
        _duplicatedNickname = nickname.trim();
        nicknameState = CheckState.unavailable;
      }
    } catch (_) {
      nicknameState = CheckState.error;
    }

    notifyListeners();
  }

  Future<void> checkEmail(String email) async {
    if (email.trim().isEmpty) {
      emailState = CheckState.idle;
      notifyListeners();
      return;
    }

    emailState = CheckState.loading;
    notifyListeners();

    try {
      final result = await _service.checkEmail(
        email.trim(),
      );

      _checkedEmail = email.trim();

      emailState = result.available
          ? CheckState.available
          : CheckState.unavailable;
    } catch (_) {
      emailState = CheckState.error;
    }

    notifyListeners();
  }

  void onNicknameChanged(String nickname) {
    final value = nickname.trim();

    if (value == _duplicatedNickname) {
        nicknameState = CheckState.unavailable;
    } else if (value != _checkedNickname) {
        nicknameState = CheckState.idle;
    }

    notifyListeners();
  }

  void onEmailChanged(String email) {
    if (email.trim() != _checkedEmail) {
      emailState = CheckState.idle;
      notifyListeners();
    }
  }

  void onPasswordChanged() {
    passwordErrorText = null;
    notifyListeners();
  }

  bool get isNicknameAvailable =>
      nicknameState == CheckState.available;

  bool get isEmailAvailable =>
      emailState == CheckState.available;

  Future<void> submit(
    CreateMemberRequest request,
  ) async {
    if (submitStatus == SubmitStatus.submitting) {
      return;
    }

    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);

      final id = response.result?.memberId;

      if (id == null) {
        throw StateError(
          '회원가입 결과에 memberId가 없습니다.',
        );
      }

      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;

      final message =
          writeSignUpErrorMessage(error);

      if (error.response?.statusCode == 400 &&
          message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on StateError {
      submitStatus = SubmitStatus.error;
      snackbarMessage =
          '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }

    notifyListeners();
  }
}