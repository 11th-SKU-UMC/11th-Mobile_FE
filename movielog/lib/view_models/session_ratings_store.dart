import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_dto.dart';

// v7에는 토큰 기반 '내 평점 전체 GET'이 없습니다.
// 그래서 현재 로그인 세션에서 등록 response로 받은 Rating만 메모리에 보관하고,
// 이 Rating을 v7 PATCH/DELETE로 수정·삭제합니다. 앱 재시작 뒤에는 복원되지 않습니다.
class SessionRatingsStore extends ChangeNotifier {
  final Map<int, RatingDto> _ratings = {}; // key: ratingId
  int? _sessionVersion;

  List<RatingDto> get ratings {
    final list = _ratings.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  // AuthViewModel의 sessionVersion이 바뀌면(로그인·로그아웃·만료) 이전 세션 평점을 비웁니다.
  // Provider update 중에 호출되므로 notifyListeners()를 부르지 않습니다.
  void syncSession(int sessionVersion) {
    if (_sessionVersion == sessionVersion) return;
    _sessionVersion = sessionVersion;
    _ratings.clear();
  }

  void upsert(RatingDto rating) {
    _ratings[rating.ratingId] = rating;
    notifyListeners();
  }

  void remove(int ratingId) {
    if (_ratings.remove(ratingId) != null) notifyListeners();
  }
}
