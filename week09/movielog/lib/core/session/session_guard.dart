class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;

  void update(String? accountId) {
    _accountId = accountId;
    _generation++;
  }

  bool isCurrent(int generation, String accountId) =>
      generation == _generation && accountId == _accountId;
}
