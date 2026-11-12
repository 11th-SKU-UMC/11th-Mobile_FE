import 'package:flutter/foundation.dart';

/// 회원가입으로 얻은 학습용 memberId를 앱 전체에서 공유한다.
///
/// 메모리에만 있어 앱을 재시작하면 사라진다. memberId를 안다는 것은 인증이 아니며,
/// JWT 주차에 토큰 기반 식별로 바뀐다. 비밀번호 등 다른 정보는 담지 않는다.
class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
