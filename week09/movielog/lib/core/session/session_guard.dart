class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  // 인증 호스트가 검증된 새 세션을 시작할 때만 호출합니다.
  // 화면이나 ViewModel에서 호출하지 않고, build마다 호출하지도 않습니다.
  int startSession(String accountId) {
    _accountId = accountId;
    return ++_generation; // 같은 계정이라도 토큰이 새로 발급되면 새 세션입니다.
  }

  void invalidate() {
    _accountId = null;
    _generation++;
  }

  bool isCurrent(int generation, String accountId) =>
      _generation == generation && _accountId == accountId;
}
