import 'package:flutter/foundation.dart';

import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/api_error.dart';
import '../data/services/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel(this._api, this._guard, this._email, this.movieId)
    : _generation = _guard.generation;

  final FavoriteApiService _api;
  final SessionGuard _guard;
  final String _email;
  final int _generation;
  final int movieId;

  bool? _isFavorite;
  bool _needsCheck = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  bool get _active => !isDisposed && _guard.isCurrent(_generation, _email);
  bool? get isFavorite => _active ? _isFavorite : null;
  bool get canToggle => _active && !isLoading && !isSaving;
  bool get needsCheck => _isFavorite == null || _needsCheck;
  bool get canUseForRating => canToggle && !needsCheck;

  Future<void> refresh() async {
    if (!canToggle) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      await _readStatus();
    } catch (error) {
      if (_active) _setCheckError(error);
    } finally {
      if (_active) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  Future<String?> toggle() async {
    if (!canToggle) return null;
    if (needsCheck) {
      await refresh();
      return _active ? errorMessage : null;
    }

    final wasFavorite = _isFavorite!;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (wasFavorite) {
        await _api.remove(movieId);
      } else {
        await _api.add(movieId);
      }
      if (!_active) return null;
      _isFavorite = !wasFavorite;
      return wasFavorite ? '즐겨찾기를 해제했습니다.' : '즐겨찾기에 추가했습니다.';
    } catch (error) {
      if (!_active) return null;
      final code = apiErrorCode(error);
      if ((code == 'FAVORITE409_1' && apiStatusCode(error) == 409) ||
          (code == 'FAVORITE404_1' && apiStatusCode(error) == 404)) {
        try {
          await _readStatus();
          if (!_active) return null;
          return _isFavorite! ? '이미 즐겨찾기에 등록된 영화입니다.' : '이미 즐겨찾기에서 해제된 영화입니다.';
        } catch (checkError) {
          if (_active) _setCheckError(checkError);
        }
      } else {
        _needsCheck =
            apiStatusCode(error) == null || apiStatusCode(error)! >= 500;
        errorMessage = code == 'MEMBER404_1'
            ? '회원 정보를 찾을 수 없습니다.'
            : '즐겨찾기를 변경하지 못했습니다. 다시 시도해 주세요.';
      }
      return _active ? errorMessage : null;
    } finally {
      if (_active) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> _readStatus() async {
    final result = await _api.check(movieId);
    if (!_active) return;
    _isFavorite = result.isFavorite;
    _needsCheck = false;
  }

  void _setCheckError(Object error) {
    _needsCheck = true;
    errorMessage = apiErrorCode(error) == 'MEMBER404_1'
        ? '회원 정보를 찾을 수 없습니다.'
        : '즐겨찾기 여부를 불러오지 못했습니다. 다시 시도해 주세요.';
  }
}
