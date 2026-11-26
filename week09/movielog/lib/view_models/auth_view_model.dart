import 'package:flutter/foundation.dart';

import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/api_error.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../services/token_storage.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._storage, this._authApi, this._memberApi);

  final TokenStorage _storage;
  final AuthApiService _authApi;
  final MemberApiService _memberApi;

  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  String? memberError;

  int _version = 0;
  String? _token;
  bool _disposed = false;
  bool _clearing = false;
  bool _cleanupRequired = false;
  bool _expired = false;
  bool _showExpiry = false;

  int get sessionVersion => _version;
  ({int version, String? token}) get credentials =>
      (version: _version, token: _token);

  bool _isCurrent(int version) => !_disposed && version == _version;
  bool isSignedInSession(int version) =>
      _isCurrent(version) && status == AuthStatus.signedIn;

  Future<void> restoreSession() async {
    if (_disposed ||
        _clearing ||
        (status != AuthStatus.initializing &&
            status != AuthStatus.retryRequired)) {
      return;
    }
    if (_cleanupRequired) {
      await _clearSession(expired: _expired);
      return;
    }

    final version = ++_version;
    status = AuthStatus.initializing;
    message = null;
    _token = null;
    notifyListeners();

    String? token;
    try {
      token = await _storage.readAccessToken();
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '기기에 저장된 로그인 정보를 읽지 못했어요. 다시 시도해 주세요.';
      notifyListeners();
      return;
    }
    if (!_isCurrent(version)) return;

    try {
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        _token = token;
        final verified = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verified;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } catch (_) {
      if (!_isCurrent(version)) return;
      _token = null;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  Future<bool> login(LoginRequest request) async {
    if (_disposed || status != AuthStatus.signedOut) return false;
    final version = ++_version;
    status = AuthStatus.authenticating;
    message = null;
    notifyListeners();

    try {
      final result = await _authApi.login(request);
      if (!_isCurrent(version)) return false;
      try {
        await _storage.saveAccessToken(result.accessToken);
      } catch (_) {
        if (!_isCurrent(version)) return false;
        await _clearSession(
          expired: false,
          signedOutMessage: '로그인 정보를 기기에 저장하지 못했어요. 다시 시도해 주세요.',
        );
        return false;
      }
      if (!_isCurrent(version)) return false;
      _token = result.accessToken;
      status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    } catch (error) {
      if (!_isCurrent(version)) return false;
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : apiErrorMessage(error, fallback: '로그인에 실패했어요. 다시 시도해 주세요.');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMember({bool force = false}) async {
    final version = _version;
    if (!isSignedInSession(version) ||
        memberStatus == MemberLoadStatus.loading ||
        (!force && memberStatus == MemberLoadStatus.success)) {
      return;
    }
    memberStatus = MemberLoadStatus.loading;
    memberError = null;
    notifyListeners();
    try {
      final result = await _memberApi.fetchMe();
      if (!isSignedInSession(version)) return;
      member = result;
      memberStatus = MemberLoadStatus.success;
    } catch (error) {
      if (!isSignedInSession(version)) return;
      memberStatus = MemberLoadStatus.error;
      memberError = apiErrorCode(error) == 'MEMBER404_1'
          ? '회원 정보를 찾을 수 없습니다.'
          : '내 정보를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  Future<bool> updateNickname(String nickname) async {
    final version = _version;
    if (!isSignedInSession(version) || member == null) return false;
    if (nickname == member!.nickname) return true;
    final updated = await _memberApi.updateNickname(nickname);
    if (!isSignedInSession(version)) return false;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (status == AuthStatus.signedIn) await _clearSession(expired: false);
  }

  Future<void> expireSession(int version) async {
    if (_isCurrent(version) && _token != null) {
      await _clearSession(expired: true);
    }
  }

  bool consumeSessionExpired() {
    final pending = _showExpiry;
    _showExpiry = false;
    return pending;
  }

  Future<void> _clearSession({
    required bool expired,
    String? signedOutMessage,
  }) async {
    if (_disposed || _clearing) return;
    final version = ++_version;
    _clearing = true;
    _cleanupRequired = true;
    _expired = expired;
    _token = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    memberError = null;
    message = null;
    status = AuthStatus.initializing;
    notifyListeners();
    try {
      await _storage.deleteAccessToken();
      if (!_isCurrent(version)) return;
      _cleanupRequired = false;
      _showExpiry = expired;
      status = AuthStatus.signedOut;
      message = signedOutMessage;
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '기기의 로그인 정보를 지우지 못했어요. 다시 시도해 주세요.';
    } finally {
      _clearing = false;
      if (_isCurrent(version)) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
