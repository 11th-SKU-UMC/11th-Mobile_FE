import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_spacing.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → '내가 등록한 평점'.
///
/// 로그인 기능이 없는 6주차에는 학습용 memberId([sampleMemberId])의 공개 평점을 보여준다.
/// root Navigator 위에 열리므로 하단 NavigationBar가 없고, 앱바에 뒤로 가기가 생긴다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내가 등록한 평점', centerTitle: true),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MyRatingsLoadStatus.idle ||
              MyRatingsLoadStatus.loading => const _RatingsLoading(),
              MyRatingsLoadStatus.empty => const _RatingsEmpty(),
              MyRatingsLoadStatus.error => _RatingsError(
                message: viewModel.message ?? '평점을 불러오지 못했습니다.',
                onRetry: viewModel.load,
              ),
              MyRatingsLoadStatus.success => _RatingsList(
                ratings: viewModel.ratings,
                notice: viewModel.message,
                onRefresh: viewModel.load,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _RatingsLoading extends StatelessWidget {
  const _RatingsLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '평점을 불러오는 중',
      liveRegion: true,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _RatingsEmpty extends StatelessWidget {
  const _RatingsEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded, size: 48, color: colors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              '아직 등록된 평점이 없어요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingsError extends StatelessWidget {
  const _RatingsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 고정 너비 예시: 문구 길이와 관계없이 항상 같은 크기다.
            MovieLogButton(label: '다시 시도', width: 120, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _RatingsList extends StatelessWidget {
  const _RatingsList({
    required this.ratings,
    required this.notice,
    required this.onRefresh,
  });

  final List<RatingWithMovie> ratings;
  final String? notice;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notice = this.notice;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: ratings.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm + 4),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '학습용 memberId $sampleMemberId의 샘플 평점입니다.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (notice != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notice,
                    style: textTheme.bodySmall?.copyWith(color: colors.error),
                  ),
                ],
              ],
            );
          }
          return _RatingCard(entry: ratings[index - 1]);
        },
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  static const double _posterWidth = 64;
  static const double _posterHeight = 96;
  static const int _maxScore = 5;

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment?.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              // movie가 null이면 posterPath도 null이라 TmdbPosterImage가 placeholder를 그린다.
              child: TmdbPosterImage(
                posterPath: movie?.posterPath,
                width: _posterWidth,
                height: _posterHeight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 정보를 찾을 수 없어요',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: movie == null ? colors.onSurfaceVariant : null,
                    ),
                  ),
                  Text(
                    'movieId ${rating.movieId}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    label: '평점 ${rating.score}점',
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 1; i <= _maxScore; i++)
                            Icon(
                              i <= rating.score
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 18,
                              color: colors.primary,
                            ),
                          const SizedBox(width: AppSpacing.xs),
                          Text('${rating.score}', style: textTheme.labelLarge),
                        ],
                      ),
                    ),
                  ),
                  // comment가 없으면(null) 후기 줄 자체를 그리지 않는다.
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(comment, style: textTheme.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(rating.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 서버는 UTC로 주므로 기기 시간대로 바꿔 `yyyy.MM.dd`로 보여준다.
  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)}';
  }
}
