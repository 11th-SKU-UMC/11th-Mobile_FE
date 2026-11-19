import 'package:shared_preferences/shared_preferences.dart';

// Challenge: 이메일만 저장합니다. 비밀번호와 토큰은 절대 저장하지 않습니다.
class EmailPreference {
  EmailPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _savedEmailKey = 'movielog.saved_email';

  final SharedPreferencesAsync _preferences;

  Future<String?> read() => _preferences.getString(_savedEmailKey);

  Future<void> save(String email) =>
      _preferences.setString(_savedEmailKey, email.trim());

  Future<void> clear() => _preferences.remove(_savedEmailKey);
}
