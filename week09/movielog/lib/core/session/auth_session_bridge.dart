import '../../view_models/auth_view_model.dart';
import 'session_guard.dart';

class AuthSessionBridge {
  AuthSessionBridge(this._auth) {
    _auth.addListener(_sync);
    _sync();
  }

  final AuthViewModel _auth;
  final guard = SessionGuard();
  int? _version;
  String? _email;

  void _sync() {
    final version = _auth.sessionVersion;
    final email = _auth.status == AuthStatus.signedIn
        ? _auth.member?.email
        : null;
    if (_version == version && _email == email) return;
    _version = version;
    _email = email;
    guard.update(email);
  }

  void dispose() {
    _auth.removeListener(_sync);
    guard.update(null);
  }
}
