import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';
import 'submit_status.dart';

/// 영화 상세 화면의 현재 영화(TMDB DTO)와 평점 등록 상태를 관리합니다.
/// 사용자 식별은 memberId가 아니라 보호용 Client의 Authorization 헤더가 맡습니다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this._auth, this._store, this.movie);

  final RatingApiService _ratingService;
  final AuthViewModel _auth;
  final SessionRatingsStore _store;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  bool get isSignedIn => _auth.status == AuthStatus.signedIn;

  Future<void> createRating({required int score, String? comment}) async {
    if (!isSignedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인이 필요해요.';
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;

    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      final rating = await _ratingService.createRating(
        CreateRatingRequest(
          movieId: movie.id, // 영화 배열 index가 아니라 TMDB id입니다.
          score: score,
          comment: comment,
        ),
      );
      // 로그아웃·회원 전환 뒤 늦게 도착한 응답은 반영하지 않습니다.
      if (_disposed || version != _auth.sessionVersion) return;
      _store.add(rating); // 등록 result의 Rating 객체를 현재 세션 목록에 보관합니다.
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed || version != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error);
      // 401(AUTH401_2/3/4)만 세션 정리. 403·409는 안내만 하고 로그인 상태를 유지합니다.
      if (isSessionExpiredCode(apiErrorCode(error))) {
        await _auth.expireSession();
      }
    } catch (_) {
      if (_disposed || version != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '응답을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
