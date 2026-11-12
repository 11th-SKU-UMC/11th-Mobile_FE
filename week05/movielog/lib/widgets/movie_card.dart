import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_spacing.dart';
import 'tmdb_poster_image.dart';

/// `release_date`(yyyy-MM-dd)에서 연도만 꺼낸다. 개봉일이 없으면 null.
String? releaseYearOf(TmdbMovieDto movie) {
  final date = movie.releaseDate;
  if (date == null || date.length < 4) return null;
  return date.substring(0, 4);
}

/// 포스터 위에 겹쳐 보여주는 TMDB 평균 평점(10점 만점) 배지. 예: ★ 7.8
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 포스터 + 제목 + 연도·장르로 구성된 영화 카드.
///
/// 홈의 가로 목록과 영화 목록의 Grid에서 함께 쓴다.
/// 카드 전체를 [GestureDetector]로 감싸 어디를 눌러도 [onTap]이 실행된다.
class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.genreName,
  });

  final TmdbMovieDto movie;
  final VoidCallback onTap;

  /// 대표 장르 이름. 장르 목록을 모르는 화면(홈)에서는 null이라 연도만 보여준다.
  final String? genreName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [?releaseYearOf(movie), ?genreName].join(' · ');

    return GestureDetector(
      // 투명한 여백을 눌러도 탭으로 인식하도록 한다.
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${movie.title} 상세 보기',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TmdbPosterImage(posterPath: movie.posterPath),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: RatingBadge(rating: movie.voteAverage),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
