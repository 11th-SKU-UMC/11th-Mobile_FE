import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 토큰 저장·조회·삭제 규칙을 인증 흐름에서 분리한 추상화입니다.
/// 인증 로직이 FlutterSecureStorage에 직접 의존하지 않으므로 테스트에서 대체할 수 있습니다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain·Android Keystore로 암호화해 저장합니다.
/// SharedPreferences는 평문 저장이므로 토큰에 쓰지 않습니다.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
