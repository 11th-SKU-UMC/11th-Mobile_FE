import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';
import 'package:movielog/view_models/submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._auth,
    this._sessionRatings,
    this.movie,
  );
  final RatingApiService _ratingService;
  final AuthViewModel _auth; // 8주차: memberId 대신 로그인 세션
  final SessionRatingsStore _sessionRatings;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  bool get isSignedIn => _auth.status == AuthStatus.signedIn;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    if (!isSignedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인 후 평점을 남길 수 있어요.';
      _notify();
      return;
    }
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      // path·body에 memberId 없음. Authorization 헤더만으로 회원을 식별합니다.
      final created = await _ratingService.createRating(
        CreateRatingRequest(
          movieId: movie.id, // TMDB id (배열 index 아님)
          score: score,
          comment: comment,
        ),
      );
      // 로그아웃·계정 전환 뒤 늦게 도착한 응답은 반영하지 않습니다.
      if (version != _auth.sessionVersion) return;
      _sessionRatings.upsert(created); // 등록 result의 Rating 객체로 현재 세션 목록 갱신
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (version != _auth.sessionVersion) return;
      if (isSessionExpiredCode(apiErrorCode(error))) {
        await _auth.expireSession(); // signedOut → Router가 /login으로 이동
      }
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      // 409(이미 등록)·400 등은 안내만 하고 로그인 상태를 유지합니다.
      submitMessage = writeErrorMessage(error);
    } on StateError catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = error.message;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
