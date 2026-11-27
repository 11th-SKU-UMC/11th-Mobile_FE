import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

// 8주차: v7에는 토큰 기반 '내 평점 전체 GET'이 없습니다.
// 현재 로그인 세션에서 등록 response로 받은 Rating(SessionRatingsStore)을 보여주고,
// 수정·삭제는 v7 PATCH/DELETE + Bearer 토큰으로 보냅니다. memberId는 쓰지 않습니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._sessionRatings,
    this._auth,
  ) {
    _sessionRatings.addListener(_onSessionRatingsChanged);
  }

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingsStore _sessionRatings;
  final AuthViewModel _auth;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning; // (7주차 화면 호환용) 현재는 사용하지 않습니다.

  // ───── 현재 세션 평점 + TMDB 영화 정보 결합 ─────
  Future<void> load() async {
    final version = ++_requestVersion;
    if (ratings.isEmpty) {
      status = MyRatingsLoadStatus.loading;
      _notify();
    }
    final rawRatings = _sessionRatings.ratings;
    final entries = <RatingWithMovie>[];
    var missingMovies = 0;
    for (final rating in rawRatings) {
      if (!_movieCache.containsKey(rating.movieId)) {
        try {
          _movieCache[rating.movieId] = await _movieService.findMovieById(
            rating.movieId,
          );
        } on DioException {
          // 일시적 실패는 캐시하지 않습니다. 평점은 placeholder로 표시합니다.
        }
        if (_disposed || version != _requestVersion) return;
      }
      final movie = _movieCache[rating.movieId];
      if (movie == null) missingMovies++;
      entries.add(RatingWithMovie(rating: rating, movie: movie));
    }
    if (_disposed || version != _requestVersion) return;
    ratings = entries;
    message = missingMovies > 0
        ? '일부 영화 정보를 가져오지 못해 "영화 #ID"로 대신 표시합니다.'
        : null;
    status = entries.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    // 사라진 평점은 선택에서도 제거합니다.
    final ids = entries.map((e) => e.rating.ratingId).toSet();
    selectedRatingIds.removeWhere((id) => !ids.contains(id));
    if (entries.isEmpty) isSelectionMode = false;
    _notify();
  }

  void _onSessionRatingsChanged() {
    if (!_disposed) load();
  }

  // 보호 요청 공통 오류 처리: 401은 세션 정리, 404는 목록에서 제거, 403·409는 안내만.
  Future<void> _handleWriteError(DioException error, int ratingId) async {
    final code = apiErrorCode(error);
    if (isSessionExpiredCode(code)) {
      await _auth.expireSession(); // Router가 /login으로 보냅니다.
    } else if (code == 'RATING404_1') {
      _sessionRatings.remove(ratingId); // 서버에 없는 평점은 목록에서 정리
    }
  }

  // ───── 수정: result Rating으로 카드 갱신 (GET 재조회 없음) ─────
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final version = _auth.sessionVersion;
    final RatingDto updated;
    try {
      updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment, // Dialog가 기존 값을 채워 보내므로 전체 교체가 안전합니다.
      );
    } on DioException catch (error) {
      if (version == _auth.sessionVersion) {
        await _handleWriteError(error, ratingId);
      }
      rethrow; // Dialog가 실패 문구를 보여줍니다.
    }
    if (version != _auth.sessionVersion) return; // 이전 세션 응답 무시
    _sessionRatings.upsert(updated);
  }

  // ───── 단일 삭제: v7은 200 + result null ─────
  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
    } on DioException catch (error) {
      if (version == _auth.sessionVersion) {
        await _handleWriteError(error, ratingId);
      }
      rethrow;
    }
    if (version != _auth.sessionVersion) return;
    _sessionRatings.remove(ratingId);
  }

  // ───── 7주차 Challenge: 다중 선택·삭제 ─────
  bool isSelectionMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  void enterSelectionMode() {
    isSelectionMode = true;
    selectedRatingIds.clear();
    _notify();
  }

  void exitSelectionMode() {
    isSelectionMode = false;
    selectedRatingIds.clear();
    _notify();
  }

  void toggleSelection(int ratingId) {
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  // 실패한 개수를 반환합니다. 실패 항목은 선택 상태를 유지합니다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    final version = _auth.sessionVersion;
    isDeletingSelected = true;
    _notify();
    var failed = 0;
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        if (version != _auth.sessionVersion) break; // 만료·로그아웃되면 중단
        try {
          await _service.deleteRating(ratingId);
          selectedRatingIds.remove(ratingId);
          _sessionRatings.remove(ratingId);
        } on DioException catch (error) {
          failed++;
          if (version == _auth.sessionVersion) {
            await _handleWriteError(error, ratingId);
          }
        } catch (_) {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }
    if (failed == 0) {
      isSelectionMode = false;
      _notify();
    }
    return failed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _sessionRatings.removeListener(_onSessionRatingsChanged);
    super.dispose();
  }
}
