import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_status.dart';

/// 마이페이지 "내가 등록한 평점"의 조회·수정·삭제를 관리합니다.
/// memberId는 회원가입 결과를 보관한 LearningMemberSession에서 받습니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  LoadStatus status = LoadStatus.idle;
  String? message;

  /// 저장은 성공했지만 목록 재조회(GET)만 실패했을 때의 안내입니다.
  String? refreshWarning;

  /// Challenge: 다중 선택 삭제 상태입니다.
  bool isEditMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = LoadStatus.loading;
    message = null;
    _notify();

    try {
      final rawRatings = await _service.fetchMemberRatings(memberId);
      if (_isStale(version)) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_isStale(version)) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않고 다음 로딩에서 재시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }

      if (_isStale(version)) return;
      ratings = entries;
      status = entries.isEmpty ? LoadStatus.empty : LoadStatus.success;
      refreshWarning = null;
      // 서버에서 사라진 평점은 선택에서도 지웁니다.
      final existingIds = entries.map((entry) => entry.rating.ratingId).toSet();
      selectedRatingIds.retainAll(existingIds);
      if (entries.isEmpty) isEditMode = false;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_isStale(version)) return;
      status = LoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }

    if (!_isStale(version)) _notify();
  }

  /// 쓰기 성공 뒤 목록을 다시 읽습니다. GET 실패는 저장 실패로 다시 던지지 않습니다.
  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    if (status == LoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      _notify();
    }
  }

  /// 쓰기 실패일 때만 예외를 다시 던져 Dialog가 실패로 처리하게 합니다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    }
    await _refreshAfterWrite();
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    }
    await _refreshAfterWrite();
  }

  // ---------------------------------------------------------------------------
  // Challenge: 다중 선택 삭제

  void enterEditMode() {
    if (isDeletingSelected) return;
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

  /// 선택된 ratingId마다 삭제 API를 호출하고, 실패한 개수를 반환합니다.
  /// 실패한 항목은 선택 상태를 유지해 다시 시도할 수 있게 합니다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사합니다.
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }

    if (failed == 0) isEditMode = false;
    await _refreshAfterWrite();
    return failed;
  }

  bool _isStale(int version) => _disposed || version != _requestVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
