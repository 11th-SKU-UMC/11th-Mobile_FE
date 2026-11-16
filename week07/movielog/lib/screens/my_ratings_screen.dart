import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/delete_rating_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => vm.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
  }

  Future<void> _delete(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          DeleteRatingDialog(onConfirm: () => vm.deleteRating(rating.ratingId)),
    );
    if (!context.mounted || deleted != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final vm = context.read<MyRatingsViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('선택한 ${vm.selectedCount}개 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    // The confirmation dialog is closed before any bulk request starts.
    if (!context.mounted || confirmed != true) return;
    await vm.deleteSelectedRatings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(vm.writeMessage ?? '삭제를 완료했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return PopScope(
      canPop: !vm.isWriting,
      child: LoadingOverlay(
        isLoading: vm.isDeletingSelected,
        child: Scaffold(
          appBar: CommonAppBar(
            title: '내가 등록한 평점',
            centerTitle: true,
            onBack: vm.isWriting
                ? null
                : () => context.canPop() ? context.pop() : context.go('/my'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (vm.refreshWarning != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Text(vm.refreshWarning!),
                  ),
                Expanded(child: _body(context, vm)),
              ],
            ),
          ),
          bottomNavigationBar: vm.isEditing && vm.ratings.isNotEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MovieLogButton(
                      label: '선택한 ${vm.selectedCount}개 삭제',
                      width: double.infinity,
                      onPressed:
                          vm.selectedCount > 0 &&
                              !vm.isWriting &&
                              vm.status == MyRatingsLoadStatus.success
                          ? () => _deleteSelected(context)
                          : null,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MyRatingsViewModel vm,
  ) => switch (vm.status) {
    MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading => const Center(
      child: CircularProgressIndicator(),
    ),
    MyRatingsLoadStatus.empty => const Center(child: Text('등록된 평점이 없습니다.')),
    MyRatingsLoadStatus.error => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.message ?? '평점을 불러오지 못했습니다.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            MovieLogButton(
              label: '조회 다시 시도',
              width: 160,
              onPressed: vm.isWriting ? null : vm.load,
            ),
          ],
        ),
      ),
    ),
    MyRatingsLoadStatus.success => RefreshIndicator(
      onRefresh: vm.isWriting ? () async {} : vm.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: vm.ratings.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vm.isEditing
                            ? '${vm.selectedCount}개 선택'
                            : '${vm.ratings.length}개의 평점',
                      ),
                    ),
                    TextButton(
                      onPressed: vm.isWriting ? null : vm.toggleEditing,
                      child: Text(vm.isEditing ? '취소' : '편집'),
                    ),
                  ],
                ),
                Text(
                  '학습용 회원 ${vm.memberId}의 평점입니다.',
                  style: AppTextStyles.bodySmall,
                ),
                if (vm.message != null) ...[
                  const SizedBox(height: 8),
                  Text(vm.message!, style: AppTextStyles.bodySmall),
                ],
              ],
            );
          }
          final entry = vm.ratings[index - 1];
          return _RatingCard(
            entry: entry,
            isEditing: vm.isEditing,
            selected: vm.selectedRatingIds.contains(entry.rating.ratingId),
            onSelect: () => vm.toggleSelected(entry.rating.ratingId),
            onEdit: vm.isWriting ? null : () => _edit(context, entry.rating),
            onDelete: vm.isWriting
                ? null
                : () => _delete(context, entry.rating),
          );
        },
      ),
    ),
  };
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.isEditing,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });
  final RatingWithMovie entry;
  final bool isEditing;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = rating.createdAt.toLocal();
    final dateText =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Container(
      key: ValueKey('rating-${rating.ratingId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.violet
              : AppColors.gray.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: entry.movie?.posterPath,
              width: 64,
              height: 96,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.movie?.title ?? '영화 정보 없음 · ${rating.movieId}',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.violet, size: 20),
                    const SizedBox(width: 4),
                    Text('${rating.score}점', style: AppTextStyles.bodyMedium),
                  ],
                ),
                if (rating.comment != null) ...[
                  const SizedBox(height: 8),
                  Text(rating.comment!, style: AppTextStyles.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(dateText, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (isEditing)
            Checkbox(value: selected, onChanged: (_) => onSelect())
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '평점 수정',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '평점 삭제',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
