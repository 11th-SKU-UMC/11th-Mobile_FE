/// 지금 도착한 응답이 현재 로그인 세션의 것인지 판정한다.
///
/// [AuthSessionBridge]만 [startSession]·[invalidate]를 호출한다.
/// 화면이나 ViewModel은 [generation]·[accountId]를 읽고 [isCurrent]로 비교만 한다.
class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  /// 인증 상태가 검증된 새 세션을 시작할 때만 호출한다. build마다 호출하지 않는다.
  /// 같은 계정이라도 토큰이 새로 발급되면 새 세션이다.
  int startSession(String accountId) {
    _accountId = accountId;
    return ++_generation;
  }

  void invalidate() {
    _accountId = null;
    _generation++;
  }

  bool isCurrent(int generation, String accountId) =>
      _generation == generation && _accountId == accountId;
}
