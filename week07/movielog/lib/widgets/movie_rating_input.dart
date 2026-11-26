import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// 별점 입력만 담당하고, 실제 별점 값은 부모 Widget이 관리합니다.
///
/// 7주차 v6 서버 연동 모드에서는 score가 1~5 정수이므로 별 한 개 단위로만 선택합니다.
/// RatingBar는 항상 double을 돌려주므로 값은 1.0, 2.0처럼 정수를 나타내는 double입니다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
    this.itemSize = 40,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  /// 저장 중에는 false로 두어 값이 바뀌지 않게 합니다.
  final bool enabled;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: itemSize,
      glow: false,
      itemBuilder: (context, index) {
        return const Icon(Icons.star, color: AppColors.star);
      },
      onRatingUpdate: onChanged,
    );
  }
}

/// 이미 저장된 별점이나 평균 별점을 읽기 전용으로 표시합니다.
class MovieRatingIndicator extends StatelessWidget {
  const MovieRatingIndicator({
    super.key,
    required this.rating,
    this.itemSize = 20,
  });

  final double rating;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemCount: 5,
      itemSize: itemSize,
      itemBuilder: (context, index) {
        return const Icon(Icons.star, color: AppColors.star);
      },
    );
  }
}
