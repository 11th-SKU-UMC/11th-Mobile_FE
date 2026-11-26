import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/movie_record_models.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/movie_record_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'load_status.dart';
import 'my_ratings_view_model.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세 화면의 영화 DTO와 평점 "등록" 상태를 관리합니다.
/// 조회·수정·삭제는 마이페이지의 MyRatingsViewModel이 담당합니다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this._ratingService,
    this._auth,
    this._myRatings,
    this.movieId, {
    this.initialMovie,
    this.recordService,
  });

  final TmdbMovieService _service;
  final RatingApiService _ratingService;

  /// Challenge: 평점·즐겨찾기 통합 저장(`POST /v8/movie-records`)에 사용합니다.
  final MovieRecordApiService? recordService;
  final AuthViewModel _auth;
  final MyRatingsViewModel _myRatings;

  /// Route의 Path Parameter로 전달받은 TMDB id입니다. 평점의 movieId로 사용합니다.
  final int? movieId;

  /// 목록에서 GoRouter extra로 넘겨준 DTO입니다. 직접 접근·Deep Link에서는 null입니다.
  final TmdbMovieDto? initialMovie;

  TmdbMovieDto? movie;
  LoadStatus status = LoadStatus.idle;
  String? message;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  /// 저장 실패지만 다시 시도해도 같은 결과인 오류(409·MEMBER404_1)라 Dialog를 닫아야 하는지 여부입니다.
  bool shouldCloseDialog = false;

  /// 영화 기록 저장 뒤 북마크를 서버 값으로 다시 맞춰야 하는지 여부입니다.
  /// 즐겨찾기 상태는 9주차부터 FavoriteDetailViewModel이 관리합니다.
  bool needsFavoriteSync = false;

  bool _disposed = false;

  bool get canRate => _auth.isSignedIn && movie != null;

  Future<void> load() async {
    final id = movieId;
    if (id == null || id < 1) {
      status = LoadStatus.error;
      message = '잘못된 영화 경로입니다.';
      notifyListeners();
      return;
    }

    final initial = initialMovie;
    if (initial != null && initial.id == id && movie == null) {
      // 목록에서 받은 DTO로 먼저 그리고, 장르 이름이 담긴 상세 응답으로 조용히 교체합니다.
      // 상세 조회가 실패해도 이미 보여준 화면은 유지합니다.
      movie = initial;
      status = LoadStatus.success;
      notifyListeners();
      try {
        final detail = await _service.findMovieById(id);
        if (_disposed || detail == null) return;
        movie = detail;
        notifyListeners();
      } on DioException {
        // 목록 DTO로 충분히 평점을 남길 수 있으므로 오류 화면으로 바꾸지 않습니다.
      }
      return;
    }

    status = LoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      movie = await _service.findMovieById(id);
      if (movie == null) {
        status = LoadStatus.empty;
      } else {
        status = LoadStatus.success;
      }
    } on DioException catch (error) {
      status = LoadStatus.error;
      message = tmdbErrorMessage(error, '영화 정보를 불러오지 못했어요.');
    }

    if (!_disposed) notifyListeners();
  }

  /// v8 토큰 기반 등록입니다. path·body에 memberId가 없습니다.
  ///
  /// - [addToFavorites]가 null이면 `POST /v8/ratings`로 평점만 저장합니다(이미 즐겨찾기한 영화).
  /// - null이 아니면 Challenge의 `POST /v8/movie-records`로 평점과 즐겨찾기를 한 번에 저장합니다.
  Future<void> createRating({
    required int score,
    String? comment,
    bool? addToFavorites,
  }) async {
    final target = movie;
    if (!_auth.isSignedIn || target == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 로그인해 주세요.';
      _notify();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;

    final recordService = this.recordService;
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    shouldCloseDialog = false;
    needsFavoriteSync = false;
    _notify();

    try {
      final RatingDto created;
      if (addToFavorites != null && recordService != null) {
        final record = await recordService.createMovieRecord(
          CreateMovieRecordRequest(
            movieId: target.id,
            score: score,
            comment: comment,
            addToFavorites: addToFavorites,
          ),
        );
        created = record.rating;
        // 북마크는 응답 값으로 바로 바꾸지 않고, 상세 화면이 서버 여부를 다시 조회합니다.
        needsFavoriteSync = true;
      } else {
        created = await _ratingService.createRating(
          CreateRatingRequest(
            movieId: target.id,
            score: score,
            comment: comment,
          ),
        );
      }
      // 로그아웃·계정 전환 뒤 늦게 온 응답은 반영하지 않습니다.
      if (version != _auth.sessionVersion) return;
      // 서버에는 이미 저장됐으므로 화면을 벗어났더라도 세션 목록에는 넣습니다.
      _myRatings.addCreated(created, target);
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (version != _auth.sessionVersion) return;
      if (isSessionExpiredError(error)) {
        await _auth.expireSession(); // signedOut → Router가 /login으로 보냅니다.
      }
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final code = apiErrorCode(error);
      // 이미 평점·즐겨찾기가 있거나 회원이 없으면 다시 눌러도 같은 결과이므로
      // Dialog를 닫고 Snackbar로 안내합니다. COMMON400·네트워크 실패는 Dialog를 열어 둡니다.
      shouldCloseDialog = _closeDialogCodes.contains(code);
      needsFavoriteSync = code == 'FAVORITE409_1';
      submitMessage = describeApiError(
        error,
        fallback: '평점을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    } on FormatException {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '서버 응답을 해석하지 못했습니다.';
    } on StateError catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = error.message;
    }
    _notify();
  }

  static const _closeDialogCodes = {
    'RATING409_1',
    'FAVORITE409_1',
    'MEMBER404_1',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
