import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._movieService);

  final TmdbMovieService _movieService;

  bool isLoading = false;
  String? errorMessage;
  List<TmdbMovieDto> movies = [];

  Future<void> loadPopular() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final page = await _movieService.fetchPopular();

      movies = page.results.take(5).toList();
    } catch (e) {
      errorMessage = '인기 영화를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
