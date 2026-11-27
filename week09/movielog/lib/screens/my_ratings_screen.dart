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

/// 마이페이지 → '내가 등록한 평점'. 수정·삭제를 한다.
///
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없어서, 이번 로그인 세션에서 등록 응답으로
/// 받은 평점만 보여준다. 앱 재시작 뒤 전체 복원은 되지 않는다는 안내를 항상 함께 보여준다.
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
            final ratings = viewModel.ratings;
            if (ratings.isEmpty) return const _RatingsEmpty();
            return _RatingsList(ratings: ratings);
          },
        ),
      ),
    );
  }
}

/// 앱 재시작 후 전체 복원이 안 된다는 안내.
class _SessionOnlyNotice extends StatelessWidget {
  const _SessionOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              MyRatingsViewModel.sessionOnlyNotice,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingsEmpty extends StatelessWidget {
  const _RatingsEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const _SessionOnlyNotice(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    size: 48,
                    color: colors.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '이번 로그인에서 등록한 평점이 없어요.\n영화 상세에서 평점을 남겨 보세요.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingsList extends StatelessWidget {
  const _RatingsList({required this.ratings});

  final List<RatingWithMovie> ratings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: ratings.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm + 4),
      itemBuilder: (context, index) {
        if (index == 0) return const _SessionOnlyNotice();
        final entry = ratings[index - 1];
        return _RatingCard(
          key: ValueKey(entry.rating.ratingId),
          entry: entry,
          onEdit: () => _onEditPressed(context, entry.rating),
          onDelete: () => _onDeletePressed(context, entry.rating),
        );
      },
    );
  }
}

/// Dialog가 [RatingDialogDismissed]로 닫힌 뒤 ViewModel이 남긴 안내를 Snackbar로 보여준다.
void _showPendingSnackBar(BuildContext context, MyRatingsViewModel viewModel) {
  final message = viewModel.takeSnackbarMessage();
  if (message == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// 기존 별점·코멘트를 채운 RatingDialog로 수정한다. 성공 시 수정 응답으로 카드를 바꾼다.
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
  if (!context.mounted) return;
  _showPendingSnackBar(context, viewModel);
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
  if (!context.mounted) return;
  _showPendingSnackBar(context, viewModel);
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
    } on RatingDialogDismissed {
      // 403·404·세션 만료는 Dialog를 닫고 화면이 안내한다.
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (error) {
      if (!mounted) return;
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
    super.key,
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
                    // TMDB 정보가 없어도 평점은 지우지 않고 placeholder로 보여준다.
                    movie?.title ?? '영화 #${rating.movieId}',
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
            // 이 목록은 현재 세션에서 내가 등록한 평점만 담으므로 모든 카드에 수정·삭제를 둔다.
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
