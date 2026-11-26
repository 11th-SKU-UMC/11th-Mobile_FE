import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBar.builder(
          initialRating: rating,
          minRating: 1,
          maxRating: 5,
          direction: Axis.horizontal,
          allowHalfRating: false,
          ignoreGestures: !enabled,
          itemCount: 5,
          itemSize: 40,
          unratedColor: Theme.of(context).colorScheme.outline
              .withValues(alpha: 0.35),
          itemPadding: const EdgeInsets.symmetric(horizontal: 2),
          itemBuilder: (context, _) =>
              Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
          onRatingUpdate: onChanged,
        ),
        const SizedBox(height: 12),
        Text(
          rating == 0 ? '별점을 선택해 주세요' : '${rating.toInt()}점',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
