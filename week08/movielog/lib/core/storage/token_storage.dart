import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// accessToken 저장·조회·삭제 규칙을 한곳에 모은 추상화.
///
/// 인증 흐름(AuthViewModel·AuthInterceptor)은 구체적인 저장소가 아니라 이 인터페이스에만
/// 의존한다. 테스트에서는 메모리 구현으로 바꿔 끼운다.
/// 비밀번호는 어떤 저장소에도 저장하지 않는다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain / Android Keystore를 쓰는 실제 저장소.
///
/// SharedPreferences는 평문 저장이라 토큰에 쓰지 않는다.
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
