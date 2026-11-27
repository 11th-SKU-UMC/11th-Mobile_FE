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

/// 앱 전체의 로그인 세션 상태.
///
/// - 신규 로그인: 로그인 API 성공 → 토큰 저장 → signedIn → MainScreen이 loadMember().
/// - 앱 재시작: 저장된 토큰 → GET me 검증 성공 뒤에만 signedIn (restoreSession).
/// - 토큰 문자열이 있다는 이유만으로 signedIn을 확정하지 않는다.
/// - 네트워크 실패는 토큰을 지우지 않고 retryRequired/error로 남긴다.
/// - [sessionVersion]이 바뀐 뒤 도착한 이전 세션 응답은 버린다.
/// - 토큰·비밀번호는 필드에 보관하거나 로그로 남기지 않는다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  static const String sessionCheckFailedMessage =
      '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
  static const String storageReadFailedMessage = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
  static const String invalidCredentialsMessage = '이메일 또는 비밀번호를 확인해 주세요.';
  static const String loginFailedMessage = '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
  static const String tokenSaveFailedMessage = '로그인 정보를 안전하게 저장하지 못했어요.';
  static const String memberLoadFailedMessage = '내 정보를 불러오지 못했어요.';
  static const String storageDeleteFailedMessage =
      '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;

  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  /// 만료(AUTH401_2/3/4)로 정리됐을 때만 true. 로그인 화면이 Snackbar로 한 번 보여준다.
  bool sessionExpired = false;

  /// 저장소 토큰 삭제 중에는 새 로그인·복원을 막는다.
  bool storageCleanupInProgress = false;

  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 앱 시작·재시도 시 저장된 토큰을 GET me로 검증한다.
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
      debugPrint('세션 확인 실패: ${error.type} ${error.response?.statusCode}');
      if (isSessionExpiredError(error)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 일시적인 실패로 유효한 토큰을 지우지 않는다.
      status = AuthStatus.retryRequired;
      message = sessionCheckFailedMessage;
    } catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('세션 확인 처리 실패: ${error.runtimeType}');
      status = AuthStatus.retryRequired;
      message = storageReadFailedMessage;
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
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      // 요청 body(비밀번호)가 남지 않도록 type·status만 기록한다.
      debugPrint('로그인 실패: ${error.type} ${error.response?.statusCode}');
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? invalidCredentialsMessage
          : loginFailedMessage;
    } catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('로그인 처리 실패: ${error.runtimeType}');
      status = AuthStatus.signedOut;
      message = error is StateError
          ? loginFailedMessage
          : tokenSaveFailedMessage;
    }
    _notify();
  }

  /// signedIn 이후 내 정보를 한 번 불러온다. 이미 있으면 [force]일 때만 다시 부른다.
  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('내 정보 조회 실패: ${error.type} ${error.response?.statusCode}');
      if (isSessionExpiredError(error)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크 실패: 로그아웃하지 않고 재시도할 수 있게 남긴다.
      memberStatus = MemberLoadStatus.error;
      message = memberLoadFailedMessage;
    } catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('내 정보 처리 실패: ${error.runtimeType}');
      memberStatus = MemberLoadStatus.error;
      message = memberLoadFailedMessage;
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 메모리의 내 정보를 교체한다. GET me를 다시 부르지 않는다.
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  /// 다른 ViewModel이 보호 요청에서 AUTH401_2/3/4를 받았을 때 부르는 공개 진입점.
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  /// 직접 로그아웃. 만료 Snackbar는 켜지 않는다.
  /// 클라이언트 저장소·메모리만 비우며 서버 토큰 폐기를 보장하지 않는다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  /// 만료 안내를 한 번 보여준 뒤 끈다.
  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> _clearCurrentSession({bool expired = true}) async {
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
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제한다.
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장이 실패했어도 삭제는 시도한다.
      }
      await _storage.deleteAccessToken();
    } catch (error) {
      debugPrint('토큰 삭제 실패: ${error.runtimeType}');
      if (_isCurrent(version)) message = storageDeleteFailedMessage;
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
