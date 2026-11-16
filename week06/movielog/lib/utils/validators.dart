/// 회원가입 입력값 검증 규칙.
///
/// `TextFormField.validator`와 같은 규칙을 따른다.
/// 유효하면 `null`, 유효하지 않으면 사용자에게 보여줄 오류 메시지를 반환한다.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _letterPattern = RegExp(r'[A-Za-z]');
  static final RegExp _digitPattern = RegExp(r'\d');

  static String? nickname(String? value) {
    final nickname = value?.trim() ?? '';

    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return '이메일 주소를 입력해주세요.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    if (!_letterPattern.hasMatch(password) ||
        !_digitPattern.hasMatch(password)) {
      return '비밀번호는 영문과 숫자를 모두 포함해야 합니다.';
    }
    return null;
  }
}
