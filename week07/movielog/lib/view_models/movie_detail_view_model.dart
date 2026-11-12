import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_status.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세 화면의 영화 DTO와 평점 "등록" 상태를 관리합니다.
/// 조회·수정·삭제는 마이페이지의 MyRatingsViewModel이 담당합니다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this._ratingService,
    this.memberId,
    this.movieId, {
    this.initialMovie,
  });

  final TmdbMovieService _service;
  final RatingApiService _ratingService;

  /// 학습용 현재 회원입니다. 로그인 인증은 아니며, 가입 전이면 null입니다.
  final int? memberId;

  /// Route의 Path Parameter로 전달받은 TMDB id입니다. 평점의 movieId로 사용합니다.
  final int? movieId;

  /// 목록에서 GoRouter extra로 넘겨준 DTO입니다. 직접 접근·Deep Link에서는 null입니다.
  final TmdbMovieDto? initialMovie;

  TmdbMovieDto? movie;
  LoadStatus status = LoadStatus.idle;
  String? message;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  // 즐겨찾기 API는 8주차 범위이므로 화면 내부 상태로만 관리합니다.
  bool isFavorite = false;

  bool _disposed = false;

  bool get canRate => memberId != null && movie != null;

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

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    final target = movie;
    if (id == null || target == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: target.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return; // 화면 이탈 뒤에는 이전 요청 결과를 반영하지 않습니다.
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    } on StateError catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = error.message;
    }
    if (!_disposed) notifyListeners();
  }

  /// 변경 후의 즐겨찾기 상태를 반환합니다.
  bool toggleFavorite() {
    isFavorite = !isFavorite;
    notifyListeners();
    return isFavorite;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
