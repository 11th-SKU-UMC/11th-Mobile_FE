import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/favorite_response_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 마이페이지 → 내 즐겨찾기 화면의 상태입니다.
///
/// 1. `GET /v8/favorites`(JWT)로 내 즐겨찾기를 가져옵니다.
/// 2. 응답에 제목·포스터가 없으므로 movieId로 TMDB 상세를 최대 [enrichmentConcurrency]개씩 조회합니다.
/// 3. 영화 한 건이 실패해도 그 카드만 placeholder가 되고 목록 전체는 유지됩니다.
///
/// 이 ViewModel은 계정·세션마다 새로 만들어집니다(Route의 ValueKey).
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
    this.enrichmentConcurrency = 5,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final Future<void> Function()? onSessionExpired;
  final int enrichmentConcurrency;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;

  /// 목록이 있는 상태에서 다시 조회하는 중인지 나타냅니다. 기존 카드를 지우지 않습니다.
  bool isRefreshing = false;

  /// 목록이 있는 상태에서 다시 조회가 실패했을 때의 안내입니다. 기존 카드는 그대로 둡니다.
  String? refreshError;

  int _refreshGeneration = 0;

  /// TMDB 공개 영화 정보 캐시입니다(key: movieId).
  /// 사용자별 즐겨찾기 상태(items)와 같은 Map에 섞지 않습니다.
  final Map<int, TmdbMovieDto> _movieCache = {};

  bool _isCurrent(int sessionGeneration, int refreshGeneration) =>
      sessionGuard.isCurrent(sessionGeneration, accountId) &&
      refreshGeneration == _refreshGeneration &&
      !isDisposed;

  /// 첫 진입과 상세에서 돌아왔을 때 호출합니다.
  Future<void> refresh() async {
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    final hadItems = items.isNotEmpty;
    if (hadItems) {
      isRefreshing = true;
    } else {
      phase = LoadPhase.loading;
    }
    errorMessage = null;
    refreshError = null;
    notifyIfAlive();

    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      final enriched = await mapBounded(
        favorites,
        enrichmentConcurrency,
        _enrich,
      );
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } on DioException catch (error) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      if (isSessionExpiredError(error)) {
        errorMessage = sessionExpiredMessage;
        await onSessionExpired?.call();
        return;
      }
      _applyListError(hadItems);
    } catch (_) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      _applyListError(hadItems);
    } finally {
      if (_isCurrent(sessionGeneration, refreshGeneration)) {
        isRefreshing = false;
        notifyIfAlive();
      }
    }
  }

  void _applyListError(bool hadItems) {
    if (hadItems) {
      refreshError = '목록을 새로 고치지 못했습니다. 최근 목록을 보여 드려요.';
    } else {
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    }
  }

  /// 즐겨찾기 1건에 TMDB 영화 정보를 붙입니다. 실패는 예외가 아니라 결과 값으로 바꿉니다.
  Future<FavoriteListItem> _enrich(FavoriteResponseDto favorite) async {
    final cached = _movieCache[favorite.movieId];
    if (cached != null) {
      return FavoriteListItem(favorite: favorite, movie: cached);
    }
    try {
      final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
      _movieCache[favorite.movieId] = movie;
      return FavoriteListItem(favorite: favorite, movie: movie);
    } on DioException catch (error) {
      return FavoriteListItem(
        favorite: favorite,
        errorMessage: error.response?.statusCode == 404
            ? 'TMDB에서 영화를 찾을 수 없습니다.'
            : '영화 정보를 불러오지 못했습니다.',
      );
    } catch (_) {
      return FavoriteListItem(
        favorite: favorite,
        errorMessage: '영화 정보를 불러오지 못했습니다.',
      );
    }
  }

  /// 정보를 못 가져온 카드 하나만 TMDB에서 다시 조회합니다. 다른 카드는 건드리지 않습니다.
  Future<void> retryMovie(int favoriteId) async {
    final sessionGeneration = sessionGuard.generation;
    final refreshGeneration = _refreshGeneration;
    if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
    final index = items.indexWhere(
      (item) => item.favorite.favoriteId == favoriteId,
    );
    if (index < 0 || items[index].hasMovie || items[index].isRetrying) return;

    _replace(
      favoriteId,
      FavoriteListItem(favorite: items[index].favorite, isRetrying: true),
    );
    final result = await _enrich(items[index].favorite);
    // 그 사이 목록을 새로 받았거나 세션이 바뀌었다면 이 결과는 버립니다.
    if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
    _replace(favoriteId, result);
  }

  void _replace(int favoriteId, FavoriteListItem next) {
    items = [
      for (final item in items)
        if (item.favorite.favoriteId == favoriteId) next else item,
    ];
    notifyIfAlive();
  }
}
