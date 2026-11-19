import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';

  static Future<void> saveAccessToken(
    String accessToken,
  ) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
  }

  static Future<String?> readAccessToken() async {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(
      key: _accessTokenKey,
    );
  }
}