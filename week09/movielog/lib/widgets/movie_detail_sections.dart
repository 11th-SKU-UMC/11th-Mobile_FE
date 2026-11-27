import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_spacing.dart';
import 'movie_card.dart';
import 'movie_rating_input.dart';

/// 상세 화면의 제목·개봉 연도·TMDB 평균 평점 영역.
class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({super.key, required this.movie, this.myRating});

  /// TMDB 평점은 10점 만점이고, 별 표시는 5점 만점이다.
  static const double _tmdbMaxRating = 10;

  final TmdbMovieDto movie;

  /// 사용자가 이번 화면에서 남긴 별점. 없으면 null.
  final double? myRating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtleStyle = textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final year = releaseYearOf(movie);
    final starRating =
        movie.voteAverage / _tmdbMaxRating * MovieRatingInput.maxRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        // 개봉일이 없으면 연도를 표시하지 않는다.
        if (year != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('$year년 개봉', style: subtleStyle),
        ],
        const SizedBox(height: AppSpacing.sm + 4),
        // 제목 옆에 북마크가 들어가 폭이 좁아졌으므로, 넘치면 다음 줄로 내린다.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.xs,
          children: [
            // 평균 평점은 사용자가 바꿀 수 없으므로 읽기 전용 Indicator로 그린다.
            MovieRatingIndicator(rating: starRating),
            const SizedBox(width: AppSpacing.sm),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('/ 10 (TMDB)', style: subtleStyle),
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
      ],
    );
  }
}

/// 상세 화면의 '시놉시스' 영역. 줄거리가 비어 있으면 안내 문구를 가운데에 보여준다.
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
        if (synopsis.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: Text(
                '줄거리 정보가 없어요.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
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

/// 상세 화면 하단에 고정된 '평점 남기기' 버튼 영역.
///
/// 즐겨찾기는 9주차부터 제목 옆 북마크(FavoriteButton)로 옮겨서, 평점 버튼이 전체 너비를 쓴다.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({super.key, required this.onRatePressed});

  /// null이면 '평점 남기기'가 비활성화된다.
  final VoidCallback? onRatePressed;

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
          child: SizedBox(
            width: double.infinity,
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
        ),
      ),
    );
  }
}
