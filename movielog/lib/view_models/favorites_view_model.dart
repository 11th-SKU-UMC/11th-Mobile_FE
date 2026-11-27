import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/data/models/favorite_list_item.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/load_phase.dart';

// 내 즐겨찾기 화면 상태
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    required this.onSessionExpired,
    this.enrichmentConcurrency = 5,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final Future<void> Function() onSessionExpired;
  final int enrichmentConcurrency;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  int _refreshGeneration = 0;

  bool _stale(int sessionGeneration, int refreshGeneration) =>
      !sessionGuard.isCurrent(sessionGeneration, accountId) ||
      refreshGeneration != _refreshGeneration ||
      isDisposed;

  // 세션 확인 → 즐겨찾기 목록 조회 → TMDB 영화 정보 보충(최대 5개씩) → 상태 결정
  Future<void> refresh() async {
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    // 이미 목록이 있으면(상세에서 돌아온 경우) 카드를 지우지 않고 그대로 둔 채 갱신합니다.
    if (items.isEmpty) phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();
    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (_stale(sessionGeneration, refreshGeneration)) return;
      // 카드 하나의 실패가 목록 전체 실패가 되지 않도록 카드별 결과로 바꿉니다.
      final enriched = await mapBounded(favorites, enrichmentConcurrency, (
        favorite,
      ) async {
        try {
          final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
          return FavoriteListItem(favorite: favorite, movie: movie);
        } catch (_) {
          return FavoriteListItem(
            favorite: favorite,
            errorMessage: '영화 정보를 불러오지 못했습니다.',
          );
        }
      });
      if (_stale(sessionGeneration, refreshGeneration)) return;
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      if (_stale(sessionGeneration, refreshGeneration)) return;
      if (isSessionExpiredError(error)) {
        await onSessionExpired(); // Router가 /login으로 이동
        return;
      }
      items = const [];
      phase = LoadPhase.error;
      errorMessage = '즐겨찾기를 불러오지 못했습니다.';
    } finally {
      if (!_stale(sessionGeneration, refreshGeneration)) notifyIfAlive();
    }
  }
}
