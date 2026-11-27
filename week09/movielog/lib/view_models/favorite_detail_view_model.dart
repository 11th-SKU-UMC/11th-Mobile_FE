import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

/// 영화 상세의 즐겨찾기(북마크) 상태.
///
/// - [isLoading]: 첫 여부 조회 중, [isSaving]: 등록·해제 중
/// - 서버 성공을 확인한 뒤에만 [isFavorite]를 바꾼다. (optimistic update 없음)
/// - 409(이미 등록)·404(이미 해제)는 POST/DELETE를 반복하지 않고 GET으로 서버 값에 맞춘다.
/// - 응답이 도착했을 때 세션이 바뀌었거나 화면이 사라졌으면 반영하지 않는다.
/// - AUTH401_2/3/4는 현재 세션의 응답일 때만 [onSessionExpired]를 한 번 부른다.
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
  });

  static const String loadFailedMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
  static const String syncFailedMessage = '서버 상태를 다시 확인하지 못했습니다.';
  static const String addFailedMessage = '즐겨찾기 등록에 실패했습니다.';
  static const String removeFailedMessage = '즐겨찾기 해제에 실패했습니다.';

  /// 상세 화면의 TMDB 영화 id. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 쓴다.
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final Future<void> Function()? onSessionExpired;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  bool _isCurrent(int generation) =>
      sessionGuard.isCurrent(generation, accountId) && !isDisposed;

  /// 세션 만료 오류면 true를 돌려주고 세션 정리를 요청한다.
  bool _handleExpired(Object error) {
    if (error is DioException && isSessionExpiredError(error)) {
      onSessionExpired?.call();
      return true;
    }
    return false;
  }

  /// 상세 화면 초기화 때 한 번 부른다. 실패하면 새로고침 버튼에서 다시 부른다.
  Future<void> load() async {
    if (isLoading || isSaving) return;
    final generation = sessionGuard.generation;
    if (!_isCurrent(generation)) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!_isCurrent(generation)) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _logFailure('즐겨찾기 여부 조회 실패', error);
      if (_handleExpired(error)) return;
      errorMessage = loadFailedMessage;
    } finally {
      if (_isCurrent(generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  /// 등록·해제. 요청 중에는 중복 탭을 막고, timeout이어도 POST를 자동 재시도하지 않는다.
  Future<void> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return;
    final generation = sessionGuard.generation;
    if (!_isCurrent(generation)) return;
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
      if (!_isCurrent(generation)) return;
      isFavorite = !before;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _logFailure(before ? '즐겨찾기 해제 실패' : '즐겨찾기 등록 실패', error);
      if (_handleExpired(error)) return;
      final code = error is DioException ? apiErrorCode(error) : null;
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        // 이미 등록/해제된 상태: 서버의 현재 여부로 화면을 맞춘다.
        await _syncFromServer(generation, before);
      } else {
        isFavorite = before;
        errorMessage = before ? removeFailedMessage : addFailedMessage;
      }
    } finally {
      if (_isCurrent(generation)) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> _syncFromServer(int generation, bool before) async {
    try {
      final synced = await favoriteApi.checkFavorite(movieId: movieId);
      if (!_isCurrent(generation)) return;
      isFavorite = synced.isFavorite;
      errorMessage = null;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _logFailure('즐겨찾기 여부 재확인 실패', error);
      if (_handleExpired(error)) return;
      isFavorite = before;
      errorMessage = syncFailedMessage;
    }
  }

  /// 요청 헤더·body는 남기지 않고 type·status·code만 기록한다.
  void _logFailure(String label, Object error) {
    if (error is DioException) {
      debugPrint(
        '$label: ${error.type} ${error.response?.statusCode} '
        '${apiErrorCode(error)}',
      );
    } else {
      debugPrint('$label: ${error.runtimeType}');
    }
  }
}
