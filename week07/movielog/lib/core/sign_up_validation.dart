String? validateNickname(String? value) {
  final nickname = value?.trim() ?? '';
  if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
  if (nickname.runes.length < 2 || nickname.runes.length > 12) {
    return '닉네임은 2~12자로 입력해 주세요.';
  }
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '이메일을 입력해 주세요.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return '올바른 이메일 형식이 아닙니다.';
  }
  return null;
}

String? validatePasswordFormat(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return '비밀번호를 입력해 주세요.';
  if (password.length < 8 ||
      !RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
    return '8자 이상, 대문자·소문자·숫자·특수문자(!@#\$%^&*)를 포함해 주세요.';
  }
  return null;
}
