import 'package:shared_preferences/shared_preferences.dart';

/// 마지막으로 선택한 장르 ID 목록을 저장합니다.
/// 단순하고 중요하지 않은 설정값만 저장하며, 토큰·비밀번호는 저장하지 않습니다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const selectedGenresKey = 'selected_genre_ids';

  final SharedPreferencesAsync _preferences;

  Future<List<int>> read() async {
    final saved = await _preferences.getStringList(selectedGenresKey) ?? [];
    return saved.map(int.tryParse).whereType<int>().toList();
  }

  Future<void> save(List<int> genreIds) async {
    await _preferences.setStringList(
      selectedGenresKey,
      genreIds.map((id) => '$id').toList(),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(selectedGenresKey);
  }
}
