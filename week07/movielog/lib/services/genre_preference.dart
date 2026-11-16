import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  static const selectedGenreKey = 'selected_genre';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<String> read() async =>
      await _preferences.getString(selectedGenreKey) ?? '전체';

  Future<void> save(String genre) async {
    await _preferences.setString(selectedGenreKey, genre);
  }
}
