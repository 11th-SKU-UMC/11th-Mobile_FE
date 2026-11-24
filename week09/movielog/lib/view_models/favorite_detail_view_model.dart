import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// apiErrorCode는 8주차에서 이미 사용한 오류 code 추출 함수입니다. 프로젝트 경로에 맞게 import하세요.
import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
  });

  // 상세 화면의 TMDB 영화 ID입니다. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // 요청을 보내는 시점의 세션 번호를 record로 묶어 둡니다.
  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;
    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  bool _stale(int generation) =>
      !sessionGuard.isCurrent(generation, accountId) || isDisposed;

  Future<void> load() async {
    if (isLoading || isSaving) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (_stale(snap.generation)) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } catch (_) {
      if (_stale(snap.generation)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (!_stale(snap.generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  // 서버 성공을 확인한 뒤에 북마크 상태를 바꿉니다. 요청 중에는 중복 탭을 막습니다.
  Future<void> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
        if (_stale(snap.generation)) return;
        isFavorite = false;
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
        if (_stale(snap.generation)) return;
        isFavorite = true;
      }
    } on DioException catch (error) {
      if (_stale(snap.generation)) return;
      // 이미 등록(409)이거나 이미 해제(404)이면 서버의 현재 여부로 화면을 맞춥니다.
      // POST를 자동으로 다시 보내지 않고 GET으로 확인합니다.
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final synced = await favoriteApi.checkFavorite(movieId: movieId);
          if (_stale(snap.generation)) return;
          isFavorite = synced.isFavorite;
          errorMessage = null;
        } catch (_) {
          if (_stale(snap.generation)) return;
          isFavorite = before;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else {
        isFavorite = before;
        errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
      }
    } catch (_) {
      if (_stale(snap.generation)) return;
      isFavorite = before;
      errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
    } finally {
      if (!_stale(snap.generation)) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }
}
