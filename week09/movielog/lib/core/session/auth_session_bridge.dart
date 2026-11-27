import 'package:flutter/foundation.dart';

import 'session_guard.dart';

/// [AuthViewModel]의 상태 변화를 [SessionGuard]에 전달한다.
///
/// 연결만 담당한다. 인증 상태의 기준은 8주차 AuthViewModel이 그대로 가진다.
class AuthSessionBridge {
  AuthSessionBridge({
    required this.authSignals,
    required this.sessionVersion,
    required this.verifiedEmail,
  }) {
    authSignals.addListener(_sync);
    _sync();
  }

  final Listenable authSignals;
  final int Function() sessionVersion;

  /// signedIn이고 내 정보(GET me)가 준비되기 전까지는 null을 반환한다.
  final String? Function() verifiedEmail;

  final SessionGuard guard = SessionGuard();
  int? _seenVersion;
  String? _seenEmail;
  bool _disposed = false;

  void _sync() {
    if (_disposed) return;
    final version = sessionVersion();
    final email = verifiedEmail();
    // 닉네임 수정처럼 version·email이 그대로면 세션을 다시 시작하지 않는다.
    if (version == _seenVersion && email == _seenEmail) return;
    _seenVersion = version;
    _seenEmail = email;
    guard.invalidate();
    if (email != null) guard.startSession(email);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    authSignals.removeListener(_sync);
    guard.invalidate();
  }
}
