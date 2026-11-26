import 'package:flutter/foundation.dart';

import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/api_error.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel(this._api, this._tmdb, this._guard, this._email)
    : _generation = _guard.generation;

  final FavoriteApiService _api;
  final TmdbMovieService _tmdb;
  final SessionGuard _guard;
  final String _email;
  final int _generation;
  final _cardRequests = <int, Future<void>>{};

  List<FavoriteListItem> _items = const [];
  LoadPhase phase = LoadPhase.idle;
  String? errorMessage;

  bool get _active => !isDisposed && _guard.isCurrent(_generation, _email);
  List<FavoriteListItem> get items => _active ? _items : const [];
  bool isRetrying(int movieId) => _cardRequests.containsKey(movieId);
  bool canRetryMovie(int movieId) =>
      !isRetrying(movieId) && _cardRequests.length < 5;

  Future<void> refresh() async {
    if (!_active || phase == LoadPhase.loading) return;
    phase = LoadPhase.loading;
    _items = const [];
    errorMessage = null;
    notifyIfAlive();

    try {
      final favorites = await _api.fetchMine();
      if (!_active) return;
      await Future.wait(_cardRequests.values.toList());
      if (!_active) return;
      final movieIds = favorites
          .map((favorite) => favorite.movieId)
          .toSet()
          .toList();
      final movies = await mapBounded(movieIds, _fetchMovie, concurrency: 5);
      if (!_active) return;
      final movieById = <int, TmdbMovieDto>{
        for (final movie in movies.nonNulls) movie.id: movie,
      };
      _items = List.unmodifiable([
        for (final favorite in favorites)
          FavoriteListItem(
            favorite: favorite,
            movie: movieById[favorite.movieId],
          ),
      ]);
      phase = _items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      if (!_active) return;
      phase = LoadPhase.error;
      errorMessage = apiErrorCode(error) == 'MEMBER404_1'
          ? '회원 정보를 찾을 수 없습니다.'
          : '즐겨찾기 목록을 불러오지 못했습니다.';
    }
    notifyIfAlive();
  }

  Future<TmdbMovieDto?> _fetchMovie(int movieId) async {
    if (!_active) return null;
    try {
      return await _tmdb.fetchMovieDetails(movieId);
    } catch (_) {
      return null;
    }
  }

  Future<void> retryMovie(int movieId) async {
    if (!_active || phase != LoadPhase.ready || !canRetryMovie(movieId)) {
      return;
    }
    final request = _retryMovie(movieId);
    _cardRequests[movieId] = request;
    notifyIfAlive();
    await request;
    _cardRequests.remove(movieId);
    if (_active) notifyIfAlive();
  }

  Future<void> _retryMovie(int movieId) async {
    final movie = await _fetchMovie(movieId);
    if (!_active || phase != LoadPhase.ready || movie?.id != movieId) return;
    _items = List.unmodifiable([
      for (final item in _items)
        if (item.favorite.movieId == movieId)
          FavoriteListItem(favorite: item.favorite, movie: movie)
        else
          item,
    ]);
  }
}
