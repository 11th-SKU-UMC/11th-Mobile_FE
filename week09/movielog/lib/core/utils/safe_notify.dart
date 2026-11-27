import 'package:flutter/foundation.dart';

/// dispose된 뒤에는 notifyListeners()를 부르지 않도록 막는다.
///
/// 늦게 도착한 응답을 반영하기 전에 [isDisposed]를 확인하고,
/// notifyListeners() 대신 [notifyIfAlive]를 쓴다.
mixin SafeNotify on ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }
}
