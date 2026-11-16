import 'package:flutter/foundation.dart';

// 학습용 현재 회원. memberId만 아는 것은 인증이 아닙니다.
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
