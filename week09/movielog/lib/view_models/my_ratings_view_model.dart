import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'rating_dialog_dismissed.dart';
import 'session_ratings_store.dart';

/// '내가 등록한 평점' 화면의 상태. 수정·삭제를 담당한다.
///
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없으므로 서버에서 목록을 다시 읽지 않는다.
/// 현재 세션에서 등록 응답으로 받은 Rating([SessionRatingsStore])만 보여주고,
/// 수정·삭제 응답으로 그 목록을 갱신한다.
///
/// 실패 처리
/// - AUTH401_2/3/4: [AuthViewModel.expireSession] → Router가 /login으로 보낸다.
/// - RATING403_1·RATING409_1: Dialog를 닫고 Snackbar로 안내만 한다. 로그아웃하지 않는다.
/// - RATING404_1: 이미 없는 평점이라는 안내를 보여주고 목록에서 뺀다.
/// - 그 외: Dialog 안에 문구를 보여주고 입력을 유지한다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._auth, this._store) {
    _store.addListener(_notify);
  }

  static const String unknownWriteErrorMessage =
      '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';
  static const String sessionOnlyNotice =
      '이번 로그인에서 등록한 평점만 보여요. 앱을 다시 시작하거나 다시 로그인하면 '
      '이전에 등록한 평점 목록은 복원되지 않아요.';

  final RatingApiService _service;
  final AuthViewModel _auth;
  final SessionRatingsStore _store;
  bool _disposed = false;

  List<RatingWithMovie> get ratings => _store.ratings;

  /// Dialog를 닫은 뒤 Snackbar로 한 번 보여줄 문구.
  String? snackbarMessage;

  String? takeSnackbarMessage() {
    final message = snackbarMessage;
    snackbarMessage = null;
    return message;
  }

  /// 평점 수정. score는 항상, comment는 null이어도 명시적으로 보낸다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) {
    return _write(ratingId, (version) async {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      _store.replace(updated, sessionVersion: version);
    });
  }

  /// 평점 삭제. 성공(200)하면 목록에서 뺀다.
  Future<void> deleteRating(int ratingId) {
    return _write(ratingId, (version) async {
      await _service.deleteRating(ratingId);
      _store.remove(ratingId, sessionVersion: version);
    });
  }

  Future<void> _write(
    int ratingId,
    Future<void> Function(int version) request,
  ) async {
    final version = _auth.sessionVersion;
    bool isStale() => _disposed || version != _auth.sessionVersion;
    snackbarMessage = null;

    try {
      await request(version);
    } on DioException catch (error) {
      if (isStale()) throw const RatingDialogDismissed();
      debugPrint('평점 쓰기 실패: ${error.type} ${error.response?.statusCode}');
      switch (ratingErrorAction(error)) {
        case RatingErrorAction.expireSession:
          await _auth.expireSession();
          throw const RatingDialogDismissed();
        case RatingErrorAction.snackbar:
          snackbarMessage = writeErrorMessage(error);
          throw const RatingDialogDismissed();
        case RatingErrorAction.notFound:
          snackbarMessage = writeErrorMessage(error);
          // 서버에 없는 평점이므로 화면 목록에서도 뺀다.
          _store.remove(ratingId, sessionVersion: version);
          throw const RatingDialogDismissed();
        case RatingErrorAction.inline:
          rethrow; // Dialog가 실패 문구를 보여주고 입력을 유지한다.
      }
    } catch (error) {
      if (error is RatingDialogDismissed) rethrow;
      // DioException 외 예외(파싱 실패, 예상 밖 상태 코드 등)도 Dialog가 멈추지 않게 한다.
      if (isStale()) throw const RatingDialogDismissed();
      debugPrint('평점 쓰기 처리 실패: ${error.runtimeType}');
      throw StateError(unknownWriteErrorMessage);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_notify);
    super.dispose();
  }
}
