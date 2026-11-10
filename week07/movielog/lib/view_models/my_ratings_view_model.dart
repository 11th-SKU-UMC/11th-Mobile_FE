import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';


const int sampleMemberId = 1; // 인증된 '내 계정'이 아닌 학습용 데이터입니다.

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  // 같은 movieId는 한 번만 조회하고 캐시합니다. (null = TMDB에 없는 영화)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      // 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;

        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] =
                await _movieService.findMovieById(rating.movieId);
          } catch (_) {
            // 일시적 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }

        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }

      if (_disposed || version != _requestVersion) return;

      ratings = entries;
      // 빈 배열은 실패가 아니라 Empty 상태입니다.
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      // 응답 형식이 예상과 다른 경우에도 loading 상태에 머물지 않게 합니다.
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  // ---- 7주차 워크북 추가 코드 ----
  String? refreshWarning;

  Future<void> _refreshAfterWrite() async {
    await load(); // 6주차 load()는 GET 실패를 status=error로 기록합니다.
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    } else {
      refreshWarning = null;
    }
  }

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
      message = writeErrorMessage(error);
      notifyListeners();
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
    await _refreshAfterWrite(); // GET 실패는 저장 실패로 다시 던지지 않습니다.
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      message = writeErrorMessage(error);
      notifyListeners();
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    }
    await _refreshAfterWrite();
  }

  // ---- 7주차 Challenge: 편집(다중 선택)과 다중 삭제 ----
  final Set<int> selectedRatingIds = {};
  bool isSelecting = false; // 편집(다중 선택) 모드
  bool isDeletingSelected = false; // 삭제 중에는 로딩 오버레이와 화면 이탈 방지를 켭니다.
  int lastDeleteFailedCount = 0; // 가장 최근 다중 삭제에서 실패한 개수

  void startSelecting() {
    if (isDeletingSelected) return;
    isSelecting = true;
    selectedRatingIds.clear();
    notifyListeners();
  }

  /// 취소: 선택을 해제하고 기본 목록으로 돌아갑니다.
  void cancelSelecting() {
    if (isDeletingSelected) return;
    isSelecting = false;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelected(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    notifyListeners();
  }

  Future<void> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return;
    isDeletingSelected = true;
    lastDeleteFailedCount = 0;
    notifyListeners();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사본을 순회합니다.
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          selectedRatingIds.remove(ratingId);
        } catch (_) {
          failed++; // 실패한 항목은 선택 상태를 유지합니다.
        }
      }

      await _refreshAfterWrite(); // GET 실패는 삭제 성공 여부와 분리합니다.
      if (_disposed) return;

      lastDeleteFailedCount = failed;
      if (status == MyRatingsLoadStatus.success) {
        // 서버에서 이미 사라진 항목이 선택 상태에 남지 않게 정리합니다.
        final existing = ratings.map((entry) => entry.rating.ratingId).toSet();
        selectedRatingIds.removeWhere((id) => !existing.contains(id));
      }
      if (failed == 0 || status == MyRatingsLoadStatus.empty) {
        // 모두 삭제했거나 목록이 비었으면 편집 모드를 끝냅니다.
        isSelecting = false;
        selectedRatingIds.clear();
      }
      if (failed > 0) {
        message = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      }
    } finally {
      isDeletingSelected = false;
      if (!_disposed) notifyListeners(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}