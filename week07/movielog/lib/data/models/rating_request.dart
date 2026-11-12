/// v6 평점 score는 1~5 사이 정수입니다. 반 점이나 범위 밖 값은 조용히 바꾸지 않고 거부합니다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// 평점 등록 요청 body입니다.
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  /// 5주차 TmdbMovieDto.id입니다. 영화 배열의 index가 아닙니다.
  final int movieId;
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    // 등록 comment는 선택 항목이라 비어 있으면 빈 문자열 대신 생략합니다.
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}
