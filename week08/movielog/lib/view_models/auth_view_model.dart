import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

/// 로그인 세션의 단일 출처입니다. Router는 [status]만 보고 화면을 정합니다.
///
/// - 신규 로그인: 로그인 API 성공 → 토큰 저장 → signedIn → MainScreen이 [loadMember] 호출
/// - 앱 재시작: 토큰 읽기 → GET me 검증 성공 뒤에만 signedIn ([restoreSession])
/// - 토큰이 있다는 이유만으로 signedIn을 확정하지 않습니다.
/// - 비밀번호와 토큰 원문은 필드에 보관하거나 로그로 남기지 않습니다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;

  /// 로그인·로그아웃·만료마다 증가합니다. 이전 세션에서 늦게 도착한 응답을 걸러냅니다.
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  /// 만료로 로그아웃됐을 때만 켜집니다. 로그인 화면이 Snackbar를 한 번 띄운 뒤 끕니다.
  bool sessionExpired = false;

  bool storageCleanupInProgress = false;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool get isSignedIn => status == AuthStatus.signedIn;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 앱 시작 시 저장된 토큰을 읽고 서버(GET me)로 검증합니다.
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();

    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final verifiedMember = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verifiedMember;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      final code = apiErrorCode(error);
      // 토큰은 유효했지만 회원이 사라진 경우(MEMBER404_1)도 이 토큰으로는 더 진행할 수 없습니다.
      if (sessionExpiredCodes.contains(code) || code == 'MEMBER404_1') {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크가 잠시 끊겼다고 유효할 수 있는 토큰을 지우지 않습니다.
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    final version = ++_sessionVersion;
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      // 내 정보는 MainScreen이 처음 열릴 때 loadMember()로 한 번 불러옵니다.
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      // 로그인 실패 AUTH401_1은 Form 오류이며, 세션 만료 처리와 섞지 않습니다.
      message = switch (apiErrorCode(error)) {
        'AUTH401_1' => '이메일 또는 비밀번호를 확인해 주세요.',
        'COMMON400' => apiErrorMessage(error) ?? '입력값을 확인해 주세요.',
        _ => '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.',
      };
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  /// 로그인 상태에서 내 정보를 한 번 불러와 보관합니다. 다른 화면은 [member]를 재사용합니다.
  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답은 무시합니다.
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredError(error)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크 실패: 로그아웃하지 않고 재시도할 수 있게 둡니다.
      memberStatus = MemberLoadStatus.error;
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 메모리의 내 정보를 교체합니다. GET me를 다시 부르지 않습니다.
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  /// 다른 ViewModel이 보호 요청에서 AUTH401_2/3/4를 받았을 때 호출하는 공개 진입점입니다.
  /// 동시 요청이 여러 번 호출해도 정리는 한 번만 실행됩니다.
  Future<void> expireSession() async {
    if (status != AuthStatus.signedIn) return;
    await _clearCurrentSession(expired: true);
  }

  /// 직접 로그아웃은 만료 Snackbar를 켜지 않습니다.
  /// 클라이언트 세션만 비우며, 서버에서 토큰이 즉시 폐기된다고 보장하지는 않습니다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> _clearCurrentSession({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제합니다. 정리 중에는 새 로그인을 막습니다.
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장이 실패했더라도 삭제는 시도합니다.
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱을 다시 실행하기 전에 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
