import 'package:shared_preferences/shared_preferences.dart';

/// Challenge: "이메일 저장" 체크 시 이메일만 저장합니다.
/// 비밀번호와 토큰은 절대 여기에 저장하지 않습니다.
class EmailPreference {
  EmailPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const savedEmailKey = 'movielog.saved_email';

  final SharedPreferencesAsync _preferences;

  Future<String?> read() => _preferences.getString(savedEmailKey);

  Future<void> save(String email) =>
      _preferences.setString(savedEmailKey, email.trim());

  Future<void> clear() => _preferences.remove(savedEmailKey);
}
