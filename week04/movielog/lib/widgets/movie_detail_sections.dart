import 'package:flutter/material.dart';

import '../data/movie.dart';
import '../theme/app_spacing.dart';
import 'movie_rating_input.dart';

/// 상세 화면의 제목·정보·평균 평점·태그 영역.
class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({super.key, required this.movie, this.myRating});

  final Movie movie;

  /// 사용자가 이번 화면에서 남긴 별점. 없으면 null.
  final double? myRating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtleStyle = textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${movie.year} • ${movie.tags.take(2).join('/')} • '
          '${movie.runtimeMinutes}분',
          style: subtleStyle,
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        Row(
          children: [
            // 평균 평점은 사용자가 바꿀 수 없으므로 읽기 전용 Indicator로 그린다.
            MovieRatingIndicator(rating: movie.averageRating),
            const SizedBox(width: AppSpacing.sm),
            Text(
              movie.averageRating.toStringAsFixed(1),
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('(${_withComma(movie.ratingCount)})', style: subtleStyle),
          ],
        ),
        if (myRating != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '내 평점 ${myRating!.toStringAsFixed(1)}',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final tag in movie.tags) _TagChip(label: tag)],
        ),
      ],
    );
  }

  static String _withComma(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// 상세 화면의 '시놉시스' 영역.
class SynopsisSection extends StatelessWidget {
  const SynopsisSection({super.key, required this.synopsis});

  final String synopsis;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시놉시스',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          synopsis,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

/// 상세 화면 하단에 고정된 '즐겨찾기' / '평점 남기기' 버튼 영역.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({
    super.key,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onRatePressed,
  });

  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onRatePressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFavoritePressed,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: colors.primary),
                  ),
                  icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRatePressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('평점 남기기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
