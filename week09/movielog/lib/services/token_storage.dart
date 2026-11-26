import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> deleteAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  static const _key = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _key);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: _key);
}
