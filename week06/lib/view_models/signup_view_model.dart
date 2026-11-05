import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

enum CheckState {
  idle,
  loading,
  available,
  unavailable,
  error,
}

class SignupViewModel extends ChangeNotifier {
  SignupViewModel(this._memberCheckService);

  final MemberCheckService _memberCheckService;

  CheckState nicknameState = CheckState.idle;
  CheckState emailState = CheckState.idle;

  String _checkedNickname = '';
  String _checkedEmail = '';
  String _duplicatedNickname = '';

  Future<void> checkNickname(String nickname) async {
    if (nickname.trim().isEmpty) {
      nicknameState = CheckState.idle;
      notifyListeners();
      return;
    }

    nicknameState = CheckState.loading;
    notifyListeners();

    try {
      final result = await _memberCheckService.checkNickname(
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
      final result = await _memberCheckService.checkEmail(
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

  bool get isNicknameAvailable =>
      nicknameState == CheckState.available;

  bool get isEmailAvailable =>
      emailState == CheckState.available;
}