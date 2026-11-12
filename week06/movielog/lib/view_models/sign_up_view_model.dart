import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';
import '../utils/validators.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인 상태.
///
/// - 닉네임과 이메일은 서로 영향을 주지 않도록 상태를 필드별로 분리한다.
/// - 입력이 바뀌면 이전 확인 결과와 기다리던 응답을 무효화한다(idle).
/// - 서버가 중복이라고 답한 값은 기억해 두고, 같은 값을 다시 입력하면
///   서버에 묻지 않고 즉시 duplicated로 되돌린다. (최종 기준은 회원가입 POST의 409)
/// - duplicated 상태에서는 값을 바꾸기 전까지 다시 확인할 수 없다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service)
    : _nickname = _FieldCheck(
        duplicatedMessage: '이미 사용 중인 닉네임입니다.',
        validator: Validators.nickname,
      ),
      _email = _FieldCheck(
        duplicatedMessage: '이미 사용 중인 이메일입니다.',
        validator: Validators.email,
      );

  static const String networkErrorMessage = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
  static const String unknownErrorMessage = '중복 확인 응답을 처리하지 못했습니다. 다시 시도해 주세요.';

  final MemberCheckService _service;
  final _FieldCheck _nickname;
  final _FieldCheck _email;
  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => _nickname.canCheck;

  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => _email.canCheck;

  /// 닉네임·이메일이 모두 서버에서 사용 가능으로 확인된 상태인지.
  bool get isBothAvailable =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  void onNicknameChanged(String value) => _onChanged(_nickname, value);

  void onEmailChanged(String value) => _onChanged(_email, value);

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, _service.checkNickname);

  Future<void> checkEmail(String value) =>
      _check(_email, value, _service.checkEmail);

  void _onChanged(_FieldCheck field, String value) {
    field.applyInput(value.trim());
    _notify();
  }

  Future<void> _check(
    _FieldCheck field,
    String value,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    // 화면이 넘긴 값과 ViewModel이 알고 있는 현재 입력이 다르면 무시한다.
    if (requested != field.current || !field.canCheck) return;

    final version = field.startChecking();
    _notify();

    bool isStale() =>
        _disposed || version != field.version || field.current != requested;

    try {
      final available = await request(requested);
      if (isStale()) return;
      field.applyResult(requested, available: available);
    } on DioException catch (error) {
      if (isStale()) return;
      debugPrint('중복 확인 통신 실패: ${error.type} ${error.response?.statusCode}');
      field.applyError(networkErrorMessage);
    } catch (error) {
      // 응답 모양이 달라 파싱에 실패하는 등 DioException 외 예외도
      // checking에 멈추지 않도록 error 상태로 보낸다.
      if (isStale()) return;
      debugPrint('중복 확인 응답 처리 실패: $error');
      field.applyError(unknownErrorMessage);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}

/// 입력란 하나(닉네임 또는 이메일)의 중복 확인 상태.
class _FieldCheck {
  _FieldCheck({required this.duplicatedMessage, required this.validator});

  final String duplicatedMessage;
  final String? Function(String?) validator;

  CheckStatus status = CheckStatus.idle;
  String? errorText;

  /// 현재 입력값(trim). 응답이 도착했을 때 입력이 바뀌었는지 비교한다.
  String current = '';

  /// 마지막으로 서버가 "중복"이라고 답한 값. 같은 값 재입력 시 재요청 없이 복원한다.
  String? duplicatedValue;

  /// 요청 버전. 입력이 바뀌거나 새 요청이 시작되면 올려서 이전 응답을 버린다.
  int version = 0;

  /// 형식이 맞고, 통신 중이 아니며, 중복으로 확인된 값이 아닐 때만 확인할 수 있다.
  bool get canCheck =>
      validator(current) == null &&
      status != CheckStatus.checking &&
      status != CheckStatus.duplicated;

  void applyInput(String trimmed) {
    current = trimmed;
    version++;
    if (duplicatedValue != null && trimmed == duplicatedValue) {
      status = CheckStatus.duplicated;
      errorText = duplicatedMessage;
    } else {
      status = CheckStatus.idle;
      errorText = null;
    }
  }

  int startChecking() {
    status = CheckStatus.checking;
    errorText = null;
    return ++version;
  }

  void applyResult(String requested, {required bool available}) {
    if (available) {
      status = CheckStatus.available;
      errorText = null;
    } else {
      status = CheckStatus.duplicated;
      errorText = duplicatedMessage;
      duplicatedValue = requested;
    }
  }

  void applyError(String message) {
    status = CheckStatus.error;
    errorText = message;
  }
}
