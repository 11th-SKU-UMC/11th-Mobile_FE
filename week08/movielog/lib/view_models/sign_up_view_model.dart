import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import '../utils/validators.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인 상태와 회원가입 제출 상태.
///
/// - 닉네임과 이메일은 서로 영향을 주지 않도록 상태를 필드별로 분리한다.
/// - 입력이 바뀌면 이전 확인 결과와 기다리던 응답을 무효화한다(idle).
/// - 서버가 중복이라고 답한 값은 기억해 두고, 같은 값을 다시 입력하면
///   서버에 묻지 않고 즉시 duplicated로 되돌린다. (최종 기준은 회원가입 POST의 409)
/// - duplicated 상태에서는 값을 바꾸기 전까지 다시 확인할 수 없다.
/// - 제출(POST /v6/members) 결과는 비밀번호 400이면 [passwordErrorText],
///   그 외 400·409 등은 [snackbarMessage]로 나눠 담는다.
/// - 비밀번호는 이 클래스에 저장하거나 로그로 남기지 않는다.
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

  static const String submitErrorMessage = '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  static const String contractErrorMessage =
      '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';

  final SignUpService _service;
  final _FieldCheck _nickname;
  final _FieldCheck _email;
  bool _disposed = false;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 가입 성공 응답의 result.memberId. 성공했을 때만 값이 있다.
  int? createdMemberId;

  /// 서버가 비밀번호 형식을 거부한 400일 때만 값이 있다. 비밀번호 입력칸 errorText로 쓴다.
  String? passwordErrorText;

  /// 어느 입력칸에도 붙일 수 없는 제출 오류(그 외 400, 409, 통신 실패 등).
  /// 화면이 [takeSnackbarMessage]로 한 번만 꺼내 Snackbar로 보여준다.
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => !isSubmitting && _nickname.canCheck;

  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => !isSubmitting && _email.canCheck;

  /// 닉네임·이메일이 모두 서버에서 사용 가능으로 확인된 상태인지.
  bool get isBothAvailable =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  /// 형식 검증 외에 ViewModel이 아는 제출 조건. 둘 다 사용 가능이고 제출 중이 아니어야 한다.
  bool get canSubmit => isBothAvailable && !isSubmitting;

  void onNicknameChanged(String value) => _onChanged(_nickname, value);

  void onEmailChanged(String value) => _onChanged(_email, value);

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, _service.checkNickname);

  Future<void> checkEmail(String value) =>
      _check(_email, value, _service.checkEmail);

  /// 비밀번호를 고치면 서버가 거부했던 비밀번호 오류를 지운다.
  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    _notify();
  }

  /// [snackbarMessage]를 한 번만 꺼낸다. (다시 그려도 Snackbar가 반복되지 않게)
  String? takeSnackbarMessage() {
    final message = snackbarMessage;
    snackbarMessage = null;
    return message;
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (isSubmitting) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    _notify();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null) {
        // memberId 없이 가입 완료로 표시하지 않는다.
        throw StateError('회원가입 결과에 memberId가 없습니다.');
      }
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      // 요청 body(비밀번호)가 남지 않도록 상태 코드만 기록한다.
      debugPrint('회원가입 실패: ${error.type} ${error.response?.statusCode}');
      submitStatus = SubmitStatus.error;
      final status = error.response?.statusCode;
      final message = writeSignUpErrorMessage(error);
      if (status == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
      if (status == 409) _applyConflict(message);
    } catch (error) {
      // StateError(memberId 없음)·파싱 실패 등 DioException 외 예외도
      // submitting에 멈추지 않도록 error로 보낸다.
      if (_disposed) return;
      debugPrint('회원가입 응답 처리 실패: ${error.runtimeType}');
      submitStatus = SubmitStatus.error;
      snackbarMessage = error is StateError
          ? contractErrorMessage
          : submitErrorMessage;
    }
    _notify();
  }

  /// 최종 409는 중복 확인보다 우선한다. 해당 입력란을 중복 상태로 돌려
  /// 값을 바꾸기 전까지 다시 제출·확인할 수 없게 한다.
  void _applyConflict(String message) {
    if (message.contains('이메일')) _email.markDuplicated();
    if (message.contains('닉네임')) _nickname.markDuplicated();
  }

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

  /// 서버가 최종적으로 중복이라고 답한 현재 값을 duplicated로 기록한다.
  void markDuplicated() {
    version++;
    applyResult(current, available: false);
  }

  void applyError(String message) {
    status = CheckStatus.error;
    errorText = message;
  }
}
