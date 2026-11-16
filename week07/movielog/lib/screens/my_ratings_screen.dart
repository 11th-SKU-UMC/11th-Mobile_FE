import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/load_status.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movie_rating_input.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 위에 열리는 자식 화면입니다. root Navigator에 push되어 하단 탭이 보이지 않습니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        final isEditMode =
            viewModel.isEditMode && viewModel.status == LoadStatus.success;

        // 다중 삭제 중에는 화면 이탈을 막습니다.
        return PopScope(
          canPop: !viewModel.isDeletingSelected,
          child: LoadingOverlay(
            isLoading: viewModel.isDeletingSelected,
            child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                leading: BackButton(onPressed: () => context.pop()),
                title: const Text(
                  '내가 등록한 평점',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              body: switch (viewModel.status) {
                LoadStatus.idle || LoadStatus.loading => const LoadingView(),
                LoadStatus.error => ErrorView(
                  // 저장 성공 뒤 GET만 실패했다면 조회만 다시 시도하도록 안내합니다.
                  message: viewModel.refreshWarning ?? viewModel.message,
                  onRetry: () => context.read<MyRatingsViewModel>().load(),
                ),
                LoadStatus.empty => const EmptyView(
                  message: '아직 등록한 평점이 없어요.',
                  icon: Icons.star_outline,
                ),
                LoadStatus.success => _RatingList(viewModel: viewModel),
              },
              bottomNavigationBar: isEditMode
                  ? _DeleteSelectedBar(
                      count: viewModel.selectedRatingIds.length,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ratings = viewModel.ratings;
    final notice = viewModel.message;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: ratings.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ListHeader(viewModel: viewModel),
              if (notice != null) ...[
                const SizedBox(height: 4),
                Text(
                  notice,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          );
        }
        final entry = ratings[index - 1];
        return _RatingCard(
          entry: entry,
          isEditMode: viewModel.isEditMode,
          isSelected: viewModel.selectedRatingIds.contains(
            entry.rating.ratingId,
          ),
        );
      },
    );
  }
}

/// 기본: 왼쪽 개수 안내 + 오른쪽 "편집". 편집 모드: 왼쪽 선택 개수 + 오른쪽 "취소".
class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isEditMode = viewModel.isEditMode;
    final read = context.read<MyRatingsViewModel>();

    return Row(
      children: [
        Expanded(
          child: Text(
            isEditMode
                ? '${viewModel.selectedRatingIds.length}개 선택됨'
                // 로그인 사용자가 아니라 학습용 memberId의 데이터임을 밝힙니다.
                : '학습용 회원(memberId ${viewModel.memberId})의 평점 '
                      '${viewModel.ratings.length}개',
            style: isEditMode
                ? AppTextStyles.titleMedium.copyWith(fontSize: 14)
                : AppTextStyles.bodySmall,
          ),
        ),
        TextButton(
          onPressed: isEditMode ? read.exitEditMode : read.enterEditMode,
          child: Text(isEditMode ? '취소' : '편집'),
        ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.isEditMode,
    required this.isSelected,
  });

  final RatingWithMovie entry;
  final bool isEditMode;
  final bool isSelected;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment;

    final VoidCallback? onTap = isEditMode
        ? () => context.read<MyRatingsViewModel>().toggleSelection(
            rating.ratingId,
          )
        : movie == null
        ? null
        : () => context.push('/movies/${movie.id}', extra: movie);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // movie가 null이면 TmdbPosterImage가 placeholder를 표시합니다.
            TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 64,
              height: 96,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 정보 없음 (movieId ${rating.movieId})',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MovieRatingIndicator(
                        rating: rating.score.toDouble(),
                        itemSize: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${rating.score}점',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  // 후기가 없으면(null) 표시하지 않습니다.
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      comment,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDate(rating.createdAt)} 등록',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 이 목록은 학습용 현재 회원이 작성한 평점만 담으므로 카드마다 수정·삭제를 둡니다.
            // 편집 모드에서는 개별 버튼 대신 CheckBox를 보여줍니다.
            if (isEditMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => context
                    .read<MyRatingsViewModel>()
                    .toggleSelection(rating.ratingId),
              )
            else
              Column(
                children: [
                  IconButton(
                    tooltip: '수정',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => onEditPressed(context, rating),
                  ),
                  IconButton(
                    tooltip: '삭제',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => onDeletePressed(context, rating),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 수정 버튼: 기존 별점·코멘트를 채운 RatingDialog를 다시 엽니다.
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      // null이면 TextField가 빈 칸으로 시작합니다. 비운 채 저장하면 후기를 지웁니다.
      initialComment: rating.comment,
      onSubmit: (score, comment) async {
        try {
          await viewModel.updateRating(
            ratingId: rating.ratingId,
            score: score,
            comment: comment,
          );
        } on DioException catch (error) {
          // 400·403·404의 서버 message를 Dialog 안에 그대로 보여줍니다.
          throw StateError(writeErrorMessage(error));
        }
      },
    ),
  );

  if (!context.mounted || saved != true) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('평점을 수정했어요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// 삭제 버튼: 확인 Dialog를 열고, 삭제가 끝날 때까지 Dialog를 유지합니다.
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );

  // deleted는 실제로 삭제까지 마쳤을 때만 true입니다.
  if (!context.mounted || deleted != true) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('평점을 삭제했어요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final message = error is DioException
          ? writeErrorMessage(error)
          : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: _ConfirmDialog(
        title: '평점을 삭제할까요?',
        isLoading: _isDeleting,
        onCancel: _isDeleting ? null : () => Navigator.of(context).pop(false),
        onConfirm: _isDeleting ? null : _onConfirm,
      ),
    );
  }
}

/// 단일·다중 삭제가 함께 쓰는 확인 Dialog 레이아웃입니다.
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              '삭제한 평점은 복구할 수 없습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MovieLogButton(
                    label: '삭제',
                    width: double.infinity,
                    isLoading: isLoading,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Challenge: 선택이 1개 이상일 때만 활성화되는 하단 삭제 버튼입니다.
class _DeleteSelectedBar extends StatelessWidget {
  const _DeleteSelectedBar({required this.count});

  final int count;

  Future<void> _onPressed(BuildContext context) async {
    final viewModel = context.read<MyRatingsViewModel>();
    // 다중 삭제의 확인 Dialog는 삭제 여부만 묻고, 요청 전에 바로 닫힙니다.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDialog(
        title: '선택한 평점 $count개를 삭제할까요?',
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Dialog가 닫힌 뒤 화면의 ViewModel이 삭제를 이어받고, 그동안 로딩 오버레이를 보여줍니다.
    final messenger = ScaffoldMessenger.of(context);
    final failed = await viewModel.deleteSelectedRatings();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? '선택한 평점을 삭제했어요.'
                : '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: MovieLogButton(
          label: '선택한 $count개 삭제',
          width: double.infinity,
          height: 48,
          onPressed: count > 0 ? () => _onPressed(context) : null,
        ),
      ),
    );
  }
}
