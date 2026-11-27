import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/data/services/favorite_api_service.dart';

// 영화 상세의 즐겨찾기(북마크) 상태
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    required this.onSessionExpired,
  });

  // 상세 화면의 TMDB 영화 ID입니다. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;
  // AUTH401_2/3/4일 때 8주차 AuthViewModel.expireSession()을 호출합니다.
  final Future<void> Function() onSessionExpired;

  bool isFavorite = false; // 서버에서 확인한 값
  bool hasLoadedStatus = false;
  bool isLoading = false; // 첫 여부 조회 중
  bool isSaving = false; // 등록·해제 중
  String? errorMessage;

  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;
    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  bool _stale(int generation) =>
      !sessionGuard.isCurrent(generation, accountId) || isDisposed;

  // 현재 세션의 만료 응답일 때만 세션을 정리합니다. (이전 계정의 늦은 401은 무시)
  Future<bool> _handleExpired(Object error, int generation) async {
    if (!isSessionExpiredError(error) || _stale(generation)) return false;
    await onSessionExpired();
    return true;
  }

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
    } catch (error) {
      if (await _handleExpired(error, snap.generation)) return;
      if (_stale(snap.generation)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (!_stale(snap.generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  // 서버 성공을 확인한 뒤에 북마크 상태를 바꿉니다. (optimistic update 없음)
  // 요청 중에는 중복 탭을 막고, timeout이어도 같은 POST를 자동으로 다시 보내지 않습니다.
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
      if (await _handleExpired(error, snap.generation)) return;
      if (_stale(snap.generation)) return;
      // 이미 등록(409)이거나 이미 해제(404)이면 서버의 현재 여부로 화면을 맞춥니다.
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
        // 403·네트워크 실패 등: 로그아웃하지 않고 이전 상태를 유지합니다.
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
