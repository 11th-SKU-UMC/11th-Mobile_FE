class MemberCheckResponse {
  const MemberCheckResponse({
    required this.available,
  });

  final bool available;

  factory MemberCheckResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MemberCheckResponse(
      available: json['available'] as bool,
    );
  }
}