import 'package:shared_preferences/shared_preferences.dart';

import '../data/movie_sort.dart';

/// 영화 목록 화면의 마지막 선택값(장르 필터, 정렬)을 기기에 저장한다.
///
/// 앱을 껐다 켜도 남아 있으면 편하지만, 잃어버려도 문제없는 단순한 설정값만 저장한다.
/// JWT, 비밀번호, 개인정보처럼 민감한 값은 여기(shared_preferences)에 저장하지 않는다.
/// 그런 값은 플랫폼 보안 저장소를 쓰는 flutter_secure_storage에 저장해야 한다.
class MovieListPreferences {
  MovieListPreferences({SharedPreferencesAsync? preferences})
    : _injectedPreferences = preferences;

  static const String selectedGenresKey = 'movie_list.selected_genres';
  static const String sortKey = 'movie_list.sort';

  final SharedPreferencesAsync? _injectedPreferences;

  /// 실제로 처음 읽거나 쓸 때 만든다.
  /// (SharedPreferencesAsync는 플랫폼이 준비되지 않은 곳에서 만들면 바로 예외를 던진다.)
  late final SharedPreferencesAsync _preferences =
      _injectedPreferences ?? SharedPreferencesAsync();

  /// 마지막으로 선택한 장르 목록. 저장된 값이 없으면 빈 목록(= 전체).
  Future<List<String>> readGenres() async {
    return await _preferences.getStringList(selectedGenresKey) ?? const [];
  }

  /// 장르 목록을 저장한다. 빈 목록(전체)이면 키를 지워서 기본 상태로 돌린다.
  Future<void> saveGenres(List<String> genres) async {
    if (genres.isEmpty) {
      await _preferences.remove(selectedGenresKey);
      return;
    }
    await _preferences.setStringList(selectedGenresKey, genres);
  }

  /// 마지막으로 선택한 정렬 방식. 저장된 값이 없으면 최신순.
  Future<MovieSort> readSort() async {
    return MovieSort.fromName(await _preferences.getString(sortKey));
  }

  /// enum 객체 대신 이름(String)만 저장한다. shared_preferences는 단순 타입만 지원한다.
  Future<void> saveSort(MovieSort sort) async {
    await _preferences.setString(sortKey, sort.name);
  }

  Future<void> clear() async {
    await _preferences.remove(selectedGenresKey);
    await _preferences.remove(sortKey);
  }
}
