import 'package:flutter/foundation.dart';

/// 회원가입 결과로 받은 memberId를 앱 상단에서 보관하는 학습용 세션입니다.
///
/// memberId만 알고 있다는 사실은 인증이 아닙니다. 메모리에만 있으므로 앱을 재시작하면
/// 사라지고, JWT 주차에는 서버가 토큰으로 현재 회원을 식별하도록 바뀝니다.
class LearningMemberSession extends ChangeNotifier {
  /// 테스트에서 이미 가입한 회원 상태를 만들 때만 [_memberId]를 전달합니다.
  LearningMemberSession([this._memberId]);

  int? _memberId;

  int? get memberId => _memberId;

  void setMemberId(int id) {
    _memberId = id;
    notifyListeners();
  }

  void clear() {
    _memberId = null;
    notifyListeners();
  }
}
