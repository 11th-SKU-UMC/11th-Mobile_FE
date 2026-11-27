import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/favorite_response_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 마이페이지 → 내 즐겨찾기 화면의 상태.
///
/// 세션 확인 → 즐겨찾기 목록 조회 → movieId로 TMDB 영화 정보 보충(최대 5개씩) → 상태 결정.
/// - 목록 조회 자체가 실패하면 [LoadPhase.error], 영화 한 건만 실패하면 그 카드만 placeholder.
/// - 세션이 바뀌었거나 더 새로운 refresh가 시작됐으면 늦은 응답을 버린다.
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
    this.enrichmentConcurrency = 5,
  });

  static const String listFailedMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
  static const String movieFailedMessage = '영화 정보를 불러오지 못했습니다.';

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final Future<void> Function()? onSessionExpired;
  final int enrichmentConcurrency;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;

  /// 영화 정보를 다시 조회 중인 movieId.
  final Set<int> retryingMovieIds = {};

  int _refreshGeneration = 0;

  bool _isCurrent(int sessionGeneration, int refreshGeneration) =>
      sessionGuard.isCurrent(sessionGeneration, accountId) &&
      refreshGeneration == _refreshGeneration &&
      !isDisposed;

  /// 목록 전체를 다시 조회한다. 상세에서 돌아왔을 때도 부른다.
  Future<void> refresh() async {
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    // 이미 목록이 있으면(복귀 갱신·당겨서 새로고침) 기존 카드를 유지한 채 갱신한다.
    if (phase != LoadPhase.ready) phase = LoadPhase.loading;
    errorMessage = null;
    retryingMovieIds.clear();
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
    } catch (error) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      if (error is DioException) {
        debugPrint(
          '내 즐겨찾기 조회 실패: ${error.type} ${error.response?.statusCode} '
          '${apiErrorCode(error)}',
        );
        if (isSessionExpiredError(error)) {
          onSessionExpired?.call();
          return;
        }
      } else {
        debugPrint('내 즐겨찾기 처리 실패: ${error.runtimeType}');
      }
      items = const [];
      phase = LoadPhase.error;
      errorMessage = listFailedMessage;
    } finally {
      if (_isCurrent(sessionGeneration, refreshGeneration)) notifyIfAlive();
    }
  }

  /// 영화 정보를 못 가져온 카드 한 장만 다시 조회한다. 다른 카드는 그대로 둔다.
  Future<void> retryMovie(int movieId) async {
    final sessionGeneration = sessionGuard.generation;
    final refreshGeneration = _refreshGeneration;
    if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
    final index = items.indexWhere((item) => item.favorite.movieId == movieId);
    if (index < 0 || items[index].hasMovie) return;
    if (!retryingMovieIds.add(movieId)) return;
    notifyIfAlive();

    final updated = await _enrich(items[index].favorite);
    if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
    retryingMovieIds.remove(movieId);
    items = [
      for (final item in items)
        item.favorite.movieId == movieId ? updated : item,
    ];
    notifyIfAlive();
  }

  /// TMDB 조회 실패를 예외가 아니라 결과로 바꿔서 한 건 실패로 목록 전체가 비지 않게 한다.
  Future<FavoriteListItem> _enrich(FavoriteResponseDto favorite) async {
    try {
      final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
      return FavoriteListItem(favorite: favorite, movie: movie);
    } catch (error) {
      debugPrint('즐겨찾기 영화 정보 조회 실패: ${error.runtimeType}');
      return FavoriteListItem(
        favorite: favorite,
        errorMessage: movieFailedMessage,
      );
    }
  }
}
