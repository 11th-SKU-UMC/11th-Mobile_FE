/// 서버 평점은 1~5 정수다. 반 점 같은 값을 조용히 toInt()로 바꾸지 않고 거부한다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// `POST /v6/members/{memberId}/ratings` 요청 body.
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  /// TMDB 영화 id (`TmdbMovieDto.id`). 배열 index가 아니다.
  final int movieId;
  final int score;
  final String? comment;

  /// comment는 선택 항목이라 비어 있으면 빈 문자열 대신 생략한다.
  Map<String, dynamic> toJson() {
    final trimmed = comment?.trim();
    return {
      'movieId': movieId,
      'score': score,
      if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
    };
  }
}
