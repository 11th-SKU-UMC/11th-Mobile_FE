import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'genre_chip.dart';

class PreferredGenreSection extends StatelessWidget {
  const PreferredGenreSection({super.key, required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('선호하는 장르', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: genres.map((genre) => GenreChip(label: genre)).toList(),
        ),
      ],
    );
  }
}
