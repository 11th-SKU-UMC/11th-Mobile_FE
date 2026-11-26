import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';

/// 현재 로그인 세션에서 등록한 평점을 보관하고 v8 토큰 기반으로 수정·삭제합니다.
///
/// v8 로그인·내 정보 응답에도 memberId가 없고 토큰 기반 "내 평점 전체 GET"도 없습니다.
/// 그래서 등록 response로 받은 Rating만 이 세션에서 관리하며, 앱 재시작 뒤 기존 평점
/// 전체 복원은 계약이 확인되기 전까지 지원하지 않습니다.
///
/// 로그아웃·만료·계정 전환으로 세션이 바뀌면 이전 세션의 평점을 즉시 비웁니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._auth) {
    _ownerVersion = _auth.sessionVersion;
    _auth.addListener(_onAuthChanged);
  }

  final RatingApiService _service;
  final AuthViewModel _auth;

  late int _ownerVersion;
  bool _disposed = false;

  List<RatingWithMovie> _ratings = const [];
  List<RatingWithMovie> get ratings => _ratings;

  /// Challenge: 다중 선택 삭제 상태입니다.
  bool isEditMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  void _onAuthChanged() {
    if (_auth.sessionVersion == _ownerVersion) return;
    _ownerVersion = _auth.sessionVersion;
    _ratings = const [];
    isEditMode = false;
    selectedRatingIds.clear();
    isDeletingSelected = false;
    _notify();
  }

  RatingWithMovie? findByMovieId(int movieId) {
    for (final entry in _ratings) {
      if (entry.rating.movieId == movieId) return entry;
    }
    return null;
  }

  /// 등록 response로 받은 Rating을 목록 맨 앞에 넣습니다.
  /// 제목·포스터는 TMDB DTO에서 가져오고, 없으면 화면이 placeholder를 그립니다.
  void addCreated(RatingDto rating, TmdbMovieDto? movie) {
    _ratings = [
      RatingWithMovie(rating: rating, movie: movie),
      ..._ratings.where((entry) => entry.rating.ratingId != rating.ratingId),
    ];
    _notify();
  }

  /// 성공하면 수정 response의 Rating으로 카드를 교체합니다. 쓰기 실패는 다시 던집니다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final version = _auth.sessionVersion;
    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (_isStale(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답은 무시합니다.
      _ratings = [
        for (final entry in _ratings)
          if (entry.rating.ratingId == ratingId)
            RatingWithMovie(rating: updated, movie: entry.movie)
          else
            entry,
      ];
      _notify();
    } on DioException catch (error) {
      if (!_isStale(version)) await _handleWriteError(error, ratingId);
      rethrow;
    }
  }

  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
      if (_isStale(version)) return;
      _removeLocal(ratingId);
    } on DioException catch (error) {
      if (!_isStale(version)) await _handleWriteError(error, ratingId);
      rethrow;
    }
  }

  /// 401(AUTH401_2/3/4)은 세션 정리, 404는 서버에 없는 평점이므로 목록에서 제거합니다.
  /// 403(본인 아님)·409·400은 안내만 하고 로그아웃하지 않습니다.
  Future<void> _handleWriteError(DioException error, int ratingId) async {
    if (isSessionExpiredError(error)) {
      await _auth.expireSession();
      return;
    }
    if (apiErrorCode(error) == 'RATING404_1') _removeLocal(ratingId);
  }

  void _removeLocal(int ratingId) {
    _ratings = _ratings
        .where((entry) => entry.rating.ratingId != ratingId)
        .toList();
    selectedRatingIds.remove(ratingId);
    if (_ratings.isEmpty) isEditMode = false;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Challenge: 다중 선택 삭제

  void enterEditMode() {
    if (isDeletingSelected || _ratings.isEmpty) return;
    isEditMode = true;
    selectedRatingIds.clear();
    _notify();
  }

  void exitEditMode() {
    if (isDeletingSelected) return;
    isEditMode = false;
    selectedRatingIds.clear();
    _notify();
  }

  void toggleSelection(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  /// 선택된 ratingId마다 삭제 API를 호출하고 실패한 개수를 반환합니다.
  /// 실패한 항목은 선택 상태를 유지하고, 세션이 만료되면 남은 요청을 보내지 않습니다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    final version = _auth.sessionVersion;
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사합니다.
      for (final ratingId in selectedRatingIds.toList()) {
        if (_isStale(version)) break;
        try {
          await _service.deleteRating(ratingId);
          if (_isStale(version)) break;
          _ratings = _ratings
              .where((entry) => entry.rating.ratingId != ratingId)
              .toList();
          selectedRatingIds.remove(ratingId);
        } on DioException catch (error) {
          if (_isStale(version)) break;
          if (isSessionExpiredError(error)) {
            await _auth.expireSession();
            break;
          }
          if (apiErrorCode(error) == 'RATING404_1') {
            // 이미 서버에 없으면 목록에서도 지웁니다.
            _ratings = _ratings
                .where((entry) => entry.rating.ratingId != ratingId)
                .toList();
            selectedRatingIds.remove(ratingId);
          } else {
            failed++;
          }
        }
      }
    } finally {
      isDeletingSelected = false;
      if (failed == 0 || _ratings.isEmpty) isEditMode = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }
    return failed;
  }

  bool _isStale(int version) => _disposed || version != _auth.sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
