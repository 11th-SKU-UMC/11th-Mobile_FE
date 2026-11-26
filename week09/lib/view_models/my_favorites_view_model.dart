import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

class MyFavoritesViewModel extends ChangeNotifier {
  MyFavoritesViewModel(
    this._favoriteApiService,
    this._tmdbMovieService,
  );

  final FavoriteApiService _favoriteApiService;
  final TmdbMovieService _tmdbMovieService;

  bool isLoading = false;
  String? errorMessage;

  final List<TmdbMovieDto> movies = [];

  Future<void> loadFavorites() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final favorites =
          await _favoriteApiService.getFavorites();

      final results = await Future.wait(
        favorites.map(
          (favorite) =>
              _tmdbMovieService.fetchMovieDetail(
            favorite.movieId,
          ),
        ),
      );

      movies
        ..clear()
        ..addAll(results);
    } catch (error) {
      errorMessage = '즐겨찾기 목록을 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadFavorites();
  }
}