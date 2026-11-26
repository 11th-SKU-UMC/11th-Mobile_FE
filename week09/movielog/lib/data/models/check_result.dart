class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  /// v5는 공통 Wrapper가 없으므로 응답 body를 그대로 파싱합니다.
  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
