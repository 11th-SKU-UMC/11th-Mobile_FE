import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  // 저장과 읽기는 반드시 같은 Key를 사용
  static const _selectedGenresKey = 'selected_genres';

  final SharedPreferencesAsync _preferences;

  // 저장된 게 없으면 null → 빈 Set(= 전체 보기)
  Future<Set<String>> read() async {
    final saved = await _preferences.getStringList(_selectedGenresKey);
    return saved?.toSet() ?? <String>{};
  }

  Future<void> save(Set<String> genres) async {
    await _preferences.setStringList(_selectedGenresKey, genres.toList());
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenresKey);
  }
}