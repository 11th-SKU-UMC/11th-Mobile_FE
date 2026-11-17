import 'package:flutter/foundation.dart';

/// 학습용 현재 회원 상태입니다. 회원가입 결과의 memberId를 앱 전체에서 읽을 수 있게 보관합니다.
/// memberId만 안다고 인증된 것은 아니며, 메모리에만 있어 앱을 재시작하면 사라집니다.
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
