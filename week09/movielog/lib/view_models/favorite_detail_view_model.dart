import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

/// 영화 상세 화면의 즐겨찾기(북마크) 상태입니다.
///
/// - [isLoading]: 첫 여부 조회 중, [isSaving]: 등록·해제 중
/// - [isFavorite]: 서버에서 확인한 값만 반영합니다(optimistic update를 쓰지 않습니다).
/// - 응답이 도착했을 때 [SessionGuard]로 현재 세션인지 확인하고, 아니면 버립니다.
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
  });

  /// 상세 화면의 TMDB 영화 ID입니다. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 씁니다.
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;

  /// AUTH401_2/3/4를 받았을 때 8주차 AuthViewModel.expireSession을 호출합니다.
  final Future<void> Function()? onSessionExpired;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  /// 세션 만료로 정리됐는지 여부입니다. 화면은 이때 Snackbar를 띄우지 않습니다(로그인 화면이 안내).
  bool sessionExpired = false;

  bool get isBusy => isLoading || isSaving;

  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;
    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  bool _isCurrent(int generation) =>
      sessionGuard.isCurrent(generation, accountId) && !isDisposed;

  /// 상세 진입 시 한 번, 그리고 서버 값으로 다시 맞춰야 할 때 호출합니다. build()에서는 부르지 않습니다.
  Future<void> load() async {
    // 잘못된 경로(/movies/abc)에서는 보호 요청을 보내지 않습니다. 상세 화면이 오류를 보여 줍니다.
    if (isBusy || movieId < 1) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!_isCurrent(snap.generation)) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } on DioException catch (error) {
      if (!_isCurrent(snap.generation)) return;
      if (await _expireIfNeeded(error)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } catch (_) {
      if (!_isCurrent(snap.generation)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (_isCurrent(snap.generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  /// 서버 성공을 확인한 뒤에 북마크를 바꿉니다. 요청 중에는 중복 탭을 막습니다.
  /// timeout이어도 같은 POST를 자동으로 다시 보내지 않습니다.
  Future<void> toggle() async {
    if (isBusy || !hasLoadedStatus) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
      }
      if (!_isCurrent(snap.generation)) return;
      isFavorite = !before;
    } on DioException catch (error) {
      if (!_isCurrent(snap.generation)) return;
      if (await _expireIfNeeded(error)) return;
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        // 이미 등록(409)·이미 해제(404): POST/DELETE를 반복하지 않고 현재 여부로 화면을 맞춥니다.
        await _syncAfterConflict(snap.generation, before);
      } else if (code == 'MEMBER404_1') {
        // 즐겨찾기 없음(FAVORITE404_1)과 다른 404입니다.
        isFavorite = before;
        errorMessage = '회원 정보를 찾을 수 없습니다. 다시 로그인해 주세요.';
      } else {
        isFavorite = before;
        errorMessage = _failureMessage(before);
      }
    } catch (_) {
      if (!_isCurrent(snap.generation)) return;
      isFavorite = before;
      errorMessage = _failureMessage(before);
    } finally {
      if (_isCurrent(snap.generation)) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> _syncAfterConflict(int generation, bool before) async {
    try {
      final synced = await favoriteApi.checkFavorite(movieId: movieId);
      if (!_isCurrent(generation)) return;
      isFavorite = synced.isFavorite;
      errorMessage = null;
    } on DioException catch (error) {
      if (!_isCurrent(generation)) return;
      if (await _expireIfNeeded(error)) return;
      isFavorite = before;
      errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
    } catch (_) {
      if (!_isCurrent(generation)) return;
      isFavorite = before;
      errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
    }
  }

  /// 현재 세션의 응답이 AUTH401_2/3/4이면 세션을 한 번 정리하고 true를 반환합니다.
  /// 403·네트워크 실패는 로그아웃하지 않습니다.
  Future<bool> _expireIfNeeded(DioException error) async {
    if (!isSessionExpiredError(error)) return false;
    sessionExpired = true;
    errorMessage = sessionExpiredMessage;
    await onSessionExpired?.call();
    return true;
  }

  String _failureMessage(bool wasFavorite) =>
      wasFavorite ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
}
