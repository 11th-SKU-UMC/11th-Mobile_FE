import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

export 'submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 닉네임·이메일 한 필드의 중복 확인 상태입니다.
/// 두 필드가 서로 영향을 주지 않도록 필드마다 별도 인스턴스를 사용합니다.
class _FieldCheck {
  _FieldCheck({required this.duplicatedMessage});

  final String duplicatedMessage;

  CheckStatus status = CheckStatus.idle;
  String? errorText;
  String current = '';

  /// 마지막으로 서버가 "중복"이라고 응답한 값입니다.
  String? duplicatedValue;
  int requestVersion = 0;

  bool get canCheck =>
      current.isNotEmpty &&
      status != CheckStatus.checking &&
      status != CheckStatus.duplicated &&
      status != CheckStatus.available;

  void onChanged(String value) {
    current = value.trim();
    requestVersion++; // 기다리던 이전 응답을 무효화합니다.

    if (duplicatedValue != null && current == duplicatedValue) {
      // 서버에 다시 묻지 않고 즉시 중복 상태를 복원합니다.
      status = CheckStatus.duplicated;
      errorText = duplicatedMessage;
    } else {
      status = CheckStatus.idle;
      errorText = null;
    }
  }

  /// 중복 확인 뒤 다른 사용자가 먼저 가입해 최종 POST에서 409가 난 경우입니다.
  void markDuplicated(String message) {
    duplicatedValue = current;
    status = CheckStatus.duplicated;
    errorText = message;
  }
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  final _nickname = _FieldCheck(duplicatedMessage: '이미 사용 중인 닉네임입니다.');
  final _email = _FieldCheck(duplicatedMessage: '이미 사용 중인 이메일입니다.');

  bool _disposed = false;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 가입 성공 응답에서 읽은 실제 ID입니다.
  int? createdMemberId;

  /// 비밀번호 입력칸에 붙이는 필드 단위 서버 오류(400)입니다.
  String? passwordErrorText;

  /// 어느 입력칸에도 붙일 수 없는 화면 단위 오류(그 외 400, 409)입니다.
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => !isSubmitting && _nickname.canCheck;

  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => !isSubmitting && _email.canCheck;

  bool get isAllChecked =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  void onNicknameChanged(String value) {
    _nickname.onChanged(value);
    _notify();
  }

  void onEmailChanged(String value) {
    _email.onChanged(value);
    _notify();
  }

  /// 비밀번호를 고치면 서버가 거부했던 이전 결과를 지웁니다.
  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    _notify();
  }

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, _service.checkNickname);

  Future<void> checkEmail(String value) =>
      _check(_email, value, _service.checkEmail);

  Future<void> _check(
    _FieldCheck field,
    String value,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (requested.isEmpty || requested != field.current || !field.canCheck) {
      return;
    }

    final version = ++field.requestVersion;
    field.status = CheckStatus.checking;
    field.errorText = null;
    _notify();

    try {
      final available = await request(requested);
      if (_isStale(field, version, requested)) return;

      if (available) {
        field.status = CheckStatus.available;
        field.errorText = null;
      } else {
        field.status = CheckStatus.duplicated;
        field.errorText = field.duplicatedMessage;
        field.duplicatedValue = requested;
      }
    } on DioException {
      if (_isStale(field, version, requested)) return;
      // 정상 응답의 available: false와 통신 실패는 다른 문구로 구분합니다.
      field.status = CheckStatus.error;
      field.errorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    _notify();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (isSubmitting) return; // 연속 탭으로 같은 회원가입이 두 번 가지 않게 합니다.
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    _notify();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final status = error.response?.statusCode;
      final message = writeSignUpErrorMessage(error);
      if (status == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
        if (status == 409) _applyFinalDuplicate(message);
      }
    } on StateError {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    } on TypeError {
      // 성공 응답이 SignUpResult 계약과 다르면 가입 완료로 표시하지 않습니다.
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    _notify();
  }

  /// 409는 최종 중복 결과입니다. 해당 필드를 중복 상태로 되돌려 다시 확인하게 합니다.
  /// 서버는 이메일을 먼저 검사하므로 이메일 중복이면 닉네임 결과는 알 수 없습니다.
  void _applyFinalDuplicate(String message) {
    if (message.contains('이메일')) {
      _email.markDuplicated(message);
    } else if (message.contains('닉네임')) {
      _nickname.markDuplicated(message);
    }
  }

  bool _isStale(_FieldCheck field, int version, String requested) =>
      _disposed ||
      version != field.requestVersion ||
      field.current != requested;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.requestVersion++;
    _email.requestVersion++;
    super.dispose();
  }
}
