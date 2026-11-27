import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import 'auth_view_model.dart';

/// 현재 로그인 세션에서 등록 응답으로 받은 평점만 메모리에 보관한다.
///
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없고 로그인·내 정보 응답에 memberId도 없다.
/// 그래서 앱을 재시작하거나 다시 로그인하면 이전 평점 목록은 복원되지 않는다.
///
/// - 등록·수정·삭제는 요청을 시작한 [AuthViewModel.sessionVersion]을 함께 받는다.
///   로그아웃·회원 전환 뒤 늦게 도착한 응답은 반영하지 않는다.
/// - 세션 버전이 바뀌면(로그인·로그아웃·만료) 목록을 비운다.
class SessionRatingsStore extends ChangeNotifier {
  SessionRatingsStore(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version;
  bool _disposed = false;

  /// 최근 등록한 순서(앞이 최신).
  List<RatingWithMovie> _ratings = const [];
  List<RatingWithMovie> get ratings => _ratings;

  void _onAuthChanged() {
    if (_auth.sessionVersion == _version) return;
    _version = _auth.sessionVersion;
    if (_ratings.isEmpty) return;
    _ratings = const [];
    _notify();
  }

  bool _accepts(int sessionVersion) =>
      !_disposed &&
      sessionVersion == _auth.sessionVersion &&
      _auth.status == AuthStatus.signedIn;

  void add(
    RatingDto rating,
    TmdbMovieDto? movie, {
    required int sessionVersion,
  }) {
    _onAuthChanged();
    if (!_accepts(sessionVersion)) return;
    _ratings = [
      RatingWithMovie(rating: rating, movie: movie),
      for (final entry in _ratings)
        if (entry.rating.ratingId != rating.ratingId) entry,
    ];
    _notify();
  }

  /// 수정 응답의 Rating으로 교체한다. 영화 정보는 기존 것을 유지한다.
  void replace(RatingDto rating, {required int sessionVersion}) {
    _onAuthChanged();
    if (!_accepts(sessionVersion)) return;
    _ratings = [
      for (final entry in _ratings)
        entry.rating.ratingId == rating.ratingId
            ? RatingWithMovie(rating: rating, movie: entry.movie)
            : entry,
    ];
    _notify();
  }

  void remove(int ratingId, {required int sessionVersion}) {
    _onAuthChanged();
    if (!_accepts(sessionVersion)) return;
    _ratings = [
      for (final entry in _ratings)
        if (entry.rating.ratingId != ratingId) entry,
    ];
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
