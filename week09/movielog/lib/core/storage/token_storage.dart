import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 토큰을 저장·조회·삭제하는 규칙을 인증 흐름에서 분리한 추상화입니다.
/// 구체적인 저장소(FlutterSecureStorage)에 직접 의존하지 않게 해 줍니다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain / Android Keystore를 이용해 암호화해서 저장합니다.
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
