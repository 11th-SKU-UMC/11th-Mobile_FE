import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'sign_up_view_model.dart';

/// 영화 상세 화면의 상태. 이 화면은 평점 '등록'만 한다. (조회·수정·삭제는 마이페이지)
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this.memberId, this.movie);

  static const String signUpRequiredMessage = '먼저 회원가입을 완료해 주세요.';
  static const String unknownErrorMessage = '평점을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  final RatingApiService _ratingService;

  /// 학습용 현재 회원(LearningMemberSession). 로그인 인증은 아니다. 없으면 등록할 수 없다.
  final int? memberId;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  bool get canRate => memberId != null;

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = signUpRequiredMessage;
      _notify();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      await _ratingService.createRating(
        memberId: id,
        // movieId는 배열 index가 아니라 TMDB 영화 id다.
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      debugPrint('평점 등록 실패: ${error.type} ${error.response?.statusCode}');
      submitStatus = SubmitStatus.error;
      // 400(별점 범위)·404(유저 없음)·409(이미 평점 있음)를 서버 message로 구분한다.
      submitMessage = writeErrorMessage(error);
    } catch (error) {
      // 예상 밖 상태 코드(StateError) 등도 submitting에 멈추지 않게 한다.
      if (_disposed) return;
      debugPrint('평점 등록 처리 실패: $error');
      submitStatus = SubmitStatus.error;
      submitMessage = unknownErrorMessage;
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
