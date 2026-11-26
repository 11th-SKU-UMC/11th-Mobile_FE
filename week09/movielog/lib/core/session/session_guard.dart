/// 지금 도착한 응답이 "현재 로그인 세션"의 것인지 판정합니다.
///
/// - [generation]은 세션이 시작되거나 무효화될 때마다 1씩 올라갑니다.
/// - [accountId]는 `GET /v8/members/me`로 확인한 email입니다. memberId를 추측하지 않습니다.
/// - 같은 이메일로 다시 로그인해도 generation이 바뀌므로 새 세션입니다.
class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  /// 인증 상태가 검증된 새 세션을 시작할 때만 호출합니다([AuthSessionBridge]).
  /// 화면이나 ViewModel, build()에서는 호출하지 않습니다.
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
