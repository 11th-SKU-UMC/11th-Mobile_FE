import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import 'auth_view_model.dart';

/// 현재 로그인 세션에서 등록·수정한 Rating을 메모리에 보관합니다.
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없으므로, 등록 response로 받은 Rating을 모아 둡니다.
/// 재시작 뒤 기존 내 평점 전체 복원은 API 계약 확인 전까지 지원하지 않습니다.
/// 로그아웃·만료·회원 전환(sessionVersion 변경)이 일어나면 이전 세션 데이터를 비웁니다.
class SessionRatingsStore extends ChangeNotifier {
  SessionRatingsStore(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version;
  final List<RatingDto> _ratings = [];

  List<RatingDto> get ratings => List.unmodifiable(_ratings);

  void add(RatingDto rating) {
    _ratings.removeWhere((r) => r.ratingId == rating.ratingId);
    _ratings.insert(0, rating);
    notifyListeners();
  }

  void replace(RatingDto rating) {
    final index = _ratings.indexWhere((r) => r.ratingId == rating.ratingId);
    if (index < 0) return;
    _ratings[index] = rating;
    notifyListeners();
  }

  void remove(int ratingId) {
    final before = _ratings.length;
    _ratings.removeWhere((r) => r.ratingId == ratingId);
    if (_ratings.length != before) notifyListeners();
  }

  void _onAuthChanged() {
    final changed = _auth.sessionVersion != _version;
    _version = _auth.sessionVersion;
    if ((changed || _auth.status != AuthStatus.signedIn) && _ratings.isNotEmpty) {
      _ratings.clear();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
