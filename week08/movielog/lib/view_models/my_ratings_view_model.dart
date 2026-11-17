import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 마이페이지 → 내가 등록한 평점.
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없으므로, 현재 세션에서 등록한 Rating(SessionRatingsStore)을
/// TMDB 영화 정보와 결합해 보여줍니다. 앱 재시작 뒤 기존 평점 전체 복원은 계약 확인 전까지 지원하지 않습니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._auth,
    this._store,
  ) : _sessionVersionAtOpen = _auth.sessionVersion;

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final AuthViewModel _auth;
  final SessionRatingsStore _store;
  final int _sessionVersionAtOpen;

  // 같은 movieId는 한 번만 조회하고 캐시합니다. (null = TMDB에 없는 영화)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning; // GET이 없으므로 사용하지 않지만 화면 호환을 위해 유지합니다.

  bool get _sessionAlive =>
      !_disposed && _auth.sessionVersion == _sessionVersionAtOpen;

  /// 세션 저장소의 Rating에 TMDB 영화 정보를 결합합니다. (서버 목록 GET 없음)
  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      // 영화 조회 실패가 평점을 지우지 않습니다. 없는 영화는 placeholder로 표시합니다.
      for (final rating in _store.ratings) {
        if (!_sessionAlive || version != _requestVersion) return;

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

      if (!_sessionAlive || version != _requestVersion) return;

      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } catch (_) {
      if (!_sessionAlive || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// 쓰기 오류 공통 처리: 401(AUTH401_2/3/4)은 세션 정리, 404는 로컬 목록에서 제거,
  /// 403·409 등은 안내만 하고 로그인 상태를 유지합니다.
  Future<void> _handleWriteError(DioException error, int ratingId) async {
    final code = apiErrorCode(error);
    if (isSessionExpiredCode(code)) {
      await _auth.expireSession();
      return;
    }
    message = writeErrorMessage(error);
    if (isRatingNotFound(error)) {
      _store.remove(ratingId);
      await load();
    } else if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (!_sessionAlive) return; // 로그아웃·회원 전환 뒤 늦게 온 응답 무시
      _store.replace(updated); // 수정 result의 Rating 객체로 갱신
    } on DioException catch (error) {
      if (!_sessionAlive) rethrow;
      await _handleWriteError(error, ratingId);
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
    await load();
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(ratingId);
      if (!_sessionAlive) return;
      _store.remove(ratingId);
    } on DioException catch (error) {
      if (!_sessionAlive) rethrow;
      await _handleWriteError(error, ratingId);
      rethrow;
    }
    await load();
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
          await _service.deleteRating(ratingId);
          if (!_sessionAlive) return;
          _store.remove(ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException catch (error) {
          failed++; // 실패한 항목은 선택 상태를 유지합니다.
          // 세션이 만료됐다면 남은 요청을 더 보내지 않고 세션을 정리합니다.
          if (isSessionExpiredCode(apiErrorCode(error))) {
            await _auth.expireSession();
            break;
          }
          if (isRatingNotFound(error)) {
            _store.remove(ratingId);
            selectedRatingIds.remove(ratingId);
          }
        } catch (_) {
          failed++;
        }
      }

      await load(); // 서버 GET 없이 세션 저장소 기준으로 다시 그립니다.
      if (!_sessionAlive) return;

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