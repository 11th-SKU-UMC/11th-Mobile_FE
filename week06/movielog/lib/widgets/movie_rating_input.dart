import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBar.builder(
          initialRating: rating,
          minRating: 0.5,
          maxRating: 5,
          direction: Axis.horizontal,
          allowHalfRating: true,
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
          '${rating.toStringAsFixed(1)}점',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
