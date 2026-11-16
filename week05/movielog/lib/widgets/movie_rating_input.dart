import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// 0.5점 단위로 별점을 입력받는 위젯.
///
/// 입력 방식만 담당하고, 실제 별점 값은 부모가 [rating]으로 들고 있다가
/// [onChanged]로 새 값을 받아 갱신한다.
///
/// 주의: `RatingBar.builder`는 [rating]을 처음 한 번만 읽는다.
/// 부모가 값을 바깥에서 바꿔야 하면(예: 초기화) 이 위젯에 새 Key를 줘서 다시 만든다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.itemSize = 40,
  });

  static const int maxRating = 5;

  final double rating;
  final ValueChanged<double> onChanged;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: maxRating,
      itemSize: itemSize,
      glow: false,
      unratedColor: colors.outlineVariant,
      itemBuilder: (context, index) =>
          Icon(Icons.star_rounded, color: colors.primary),
      onRatingUpdate: onChanged,
    );
  }
}

/// 읽기 전용 별점 표시. 0.5 단위가 아닌 값(예: 4.3)도 그대로 그린다.
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
    final colors = Theme.of(context).colorScheme;

    return RatingBarIndicator(
      rating: rating,
      itemCount: MovieRatingInput.maxRating,
      itemSize: itemSize,
      unratedColor: colors.outlineVariant,
      itemBuilder: (context, index) =>
          Icon(Icons.star_rounded, color: colors.primary),
    );
  }
}
