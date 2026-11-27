import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'rating_dialog_dismissed.dart';
import 'session_ratings_store.dart';
import 'sign_up_view_model.dart';

/// 영화 상세 화면의 상태. 이 화면은 평점 '등록'만 한다. (수정·삭제는 마이페이지)
///
/// 사용자 식별은 보호 Client의 Authorization 헤더로 한다. memberId를 받지 않는다.
/// 등록 result의 Rating은 [SessionRatingsStore]에 넣어 마이페이지에서 수정·삭제한다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._auth,
    this._sessionRatings,
    this.movie,
  );

  static const String unknownErrorMessage = '평점을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  final RatingApiService _ratingService;
  final AuthViewModel _auth;
  final SessionRatingsStore _sessionRatings;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// Dialog 안에 보여줄 실패 문구(별점 범위, 네트워크 등).
  String? submitMessage;

  /// Dialog를 닫은 뒤 Snackbar로 한 번 보여줄 문구(409 등). [takeSnackbarMessage]로 꺼낸다.
  String? snackbarMessage;

  bool _disposed = false;

  String? takeSnackbarMessage() {
    final message = snackbarMessage;
    snackbarMessage = null;
    return message;
  }

  /// 실패하면 예외를 던져 RatingDialog가 처리하게 한다.
  /// - Dialog 안에 문구: StateError(submitMessage)
  /// - Dialog를 닫고 화면에서 안내: [RatingDialogDismissed]
  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    snackbarMessage = null;
    _notify();

    bool isStale() => _disposed || version != _auth.sessionVersion;

    try {
      // movieId는 배열 index가 아니라 TMDB 영화 id다.
      final created = await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      if (isStale()) throw const RatingDialogDismissed();
      _sessionRatings.add(created, movie, sessionVersion: version);
      submitStatus = SubmitStatus.success;
      _notify();
      return;
    } on RatingDialogDismissed {
      rethrow;
    } on DioException catch (error) {
      if (isStale()) throw const RatingDialogDismissed();
      debugPrint('평점 등록 실패: ${error.type} ${error.response?.statusCode}');
      submitStatus = SubmitStatus.error;
      switch (ratingErrorAction(error)) {
        case RatingErrorAction.expireSession:
          // 안내와 이동은 로그인 화면과 Router가 맡는다.
          _notify();
          await _auth.expireSession();
          throw const RatingDialogDismissed();
        case RatingErrorAction.snackbar:
        case RatingErrorAction.notFound:
          snackbarMessage = writeErrorMessage(error);
          _notify();
          throw const RatingDialogDismissed();
        case RatingErrorAction.inline:
          submitMessage = writeErrorMessage(error);
      }
    } catch (error) {
      // 응답 파싱 실패 등도 submitting에 멈추지 않게 한다.
      if (isStale()) throw const RatingDialogDismissed();
      debugPrint('평점 등록 처리 실패: ${error.runtimeType}');
      submitStatus = SubmitStatus.error;
      submitMessage = unknownErrorMessage;
    }
    _notify();
    throw StateError(submitMessage ?? unknownErrorMessage);
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
