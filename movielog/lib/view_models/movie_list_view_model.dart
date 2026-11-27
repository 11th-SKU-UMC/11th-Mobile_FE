import 'package:flutter/foundation.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

// 9주차: 5주차의 "Discover 최대 30개 수집"은 PagedMoviesViewModel(더 보기)로 대체했습니다.
// 이 ViewModel은 영화 목록 화면의 장르 Chip 목록만 담당합니다.
class MovieListViewModel extends ChangeNotifier with SafeNotify {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbGenreDto> genres = const [];
  bool _loading = false;

  Future<void> loadGenres() async {
    if (_loading || genres.isNotEmpty) return;
    _loading = true;
    try {
      final result = await _service.fetchGenres();
      if (isDisposed) return;
      genres = result;
      notifyIfAlive();
    } catch (_) {
      // 장르를 못 불러와도 "전체" 목록은 그대로 볼 수 있습니다.
    } finally {
      _loading = false;
    }
  }
}
