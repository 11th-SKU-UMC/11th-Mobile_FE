import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_spacing.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → '내가 등록한 평점'. 조회·수정·삭제를 한다.
///
/// 회원가입으로 얻은 학습용 memberId(LearningMemberSession)의 평점을 보여준다.
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
              // 저장은 성공했지만 목록 GET만 실패했다면 저장 실패처럼 보이지 않게
              // refreshWarning을 앞세우고 '조회만 다시 시도'를 안내한다.
              MyRatingsLoadStatus.error => _RatingsError(
                message:
                    viewModel.refreshWarning ??
                    viewModel.message ??
                    '평점을 불러오지 못했습니다.',
                retryLabel: viewModel.refreshWarning != null
                    ? '조회만 다시 시도'
                    : '다시 시도',
                onRetry: viewModel.load,
              ),
              MyRatingsLoadStatus.success => _RatingsList(
                memberId: viewModel.memberId,
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
  const _RatingsError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
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
            MovieLogButton(label: retryLabel, width: 160, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _RatingsList extends StatelessWidget {
  const _RatingsList({
    required this.memberId,
    required this.ratings,
    required this.notice,
    required this.onRefresh,
  });

  final int memberId;
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
                  '학습용 회원(memberId $memberId)의 평점입니다.',
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
          final entry = ratings[index - 1];
          return _RatingCard(
            entry: entry,
            onEdit: () => _onEditPressed(context, entry.rating),
            onDelete: () => _onDeletePressed(context, entry.rating),
          );
        },
      ),
    );
  }
}

/// 기존 별점·코멘트를 채운 RatingDialog로 수정한다. 성공 시 ViewModel이 목록을 다시 읽는다.
Future<void> _onEditPressed(BuildContext context, RatingDto rating) async {
  // Dialog는 root Navigator에 뜨므로 ViewModel을 미리 꺼내 둔다.
  final viewModel = context.read<MyRatingsViewModel>();
  await RatingDialog.show(
    context,
    initialScore: rating.score,
    initialComment: rating.comment, // null이면 빈 칸으로 시작한다.
    onSubmit: (score, comment) => viewModel.updateRating(
      ratingId: rating.ratingId,
      score: score,
      comment: comment,
    ),
  );
}

/// 삭제 확인 Dialog. 취소하면 요청을 보내지 않고, 삭제 중에는 닫히지 않는다.
Future<void> _onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막는다.
    builder: (_) => DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
}

/// 평점 삭제 확인 Dialog. 삭제까지 마쳤을 때만 true를 돌려준다.
class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      // 403(본인 평점 아님)과 404(이미 없는 평점)를 서버 문구로 구분해 보여준다.
      setState(() {
        _isDeleting = false;
        _errorText = RatingDialog.messageOf(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text('평점을 삭제할까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('삭제한 평점은 복구할 수 없습니다.'),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_errorText!, style: TextStyle(color: colors.error)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _onConfirm,
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  static const double _posterWidth = 64;
  static const double _posterHeight = 96;
  static const int _maxScore = 5;

  final RatingWithMovie entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
            // 이 목록은 현재 학습용 회원의 평점만 담으므로 모든 카드에 수정·삭제를 둔다.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '수정',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '삭제',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: colors.error),
                ),
              ],
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
