import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/rating_dialog.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/loading_overlay.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

const _deleteBackground = Color(0xFFFFF0F0);
const _deleteForeground = Color(0xFFB3261E);

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyRatingsViewModel>();
    final showDeleteBar =
        viewModel.isSelectionMode &&
        viewModel.status == MyRatingsLoadStatus.success;

    // Challenge: 다중 삭제 중 화면 이탈 차단 + 로딩 오버레이
    return PopScope(
      canPop: !viewModel.isDeletingSelected,
      child: LoadingOverlay(
        isLoading: viewModel.isDeletingSelected,
        child: Scaffold(
          backgroundColor: AppColors.warmWhite,
          appBar: AppBar(
            backgroundColor: AppColors.warmWhite,
            centerTitle: true,
            leading: const BackButton(),
            title: const Text('내가 등록한 평점', style: AppTextStyles.titleAppBar),
          ),
          body: _buildBody(viewModel),
          bottomNavigationBar: showDeleteBar
              ? _DeleteSelectedBar(count: viewModel.selectedRatingIds.length)
              : null,
        ),
      ),
    );
  }

  Widget _buildBody(MyRatingsViewModel viewModel) {
    switch (viewModel.status) {
      case MyRatingsLoadStatus.idle:
      case MyRatingsLoadStatus.loading:
        return const _RatingsLoading();
      case MyRatingsLoadStatus.empty:
        return const _RatingsEmpty();
      case MyRatingsLoadStatus.error:
        // 저장 성공 + GET 실패면 재조회 안내, 아니면 일반 조회 오류
        return _RatingsError(
          message:
              viewModel.refreshWarning ??
              viewModel.message ??
              '평점을 불러오지 못했습니다.',
          onRetry: viewModel.load, // GET만 다시 시도
        );
      case MyRatingsLoadStatus.success:
        return _RatingsList(viewModel: viewModel);
    }
  }
}

// ───── 수정 ─────
Future<void> _onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 빈 칸으로 시작
      onSubmit: (score, comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment, // 기존 값이 채워져 있으므로 유지 의도가 명확
      ),
    ),
  );
  if (saved == true) {
    messenger.showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
  }
}

// ───── 단일 삭제: 요청 중 Dialog 유지 ─────
Future<void> _onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeleteRatingDialog(
      title: '평점을 삭제할까요?',
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
  if (deleted == true) {
    messenger.showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
  }
}

// ───── Challenge 다중 삭제: Dialog 먼저 닫고 화면에서 삭제 ─────
Future<void> _onDeleteSelectedPressed(BuildContext context) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final count = viewModel.selectedRatingIds.length;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _DeleteRatingDialog(title: '선택한 평점 $count개를 삭제할까요?'),
  );
  if (confirmed != true || !context.mounted) return;

  final failed = await viewModel.deleteSelectedRatings();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        failed > 0
            ? '${count - failed}개 삭제, $failed개는 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'
            : '$count개 평점을 삭제했습니다.',
      ),
    ),
  );
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.title, this.onConfirm});

  final String title;
  // null이면 삭제 요청 없이 바로 true로 닫힙니다(다중 삭제용).
  final Future<void> Function()? onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '삭제한 평점은 복구할 수 없습니다.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextButton(
                        // 취소하면 삭제 API를 보내지 않습니다.
                        onPressed: _isDeleting
                            ? null
                            : () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryScale100,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: MovieLogButton(
                      label: '삭제',
                      width: double.infinity,
                      isLoading: _isDeleting,
                      onPressed: _isDeleting ? null : _onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText = describeRatingError(error); // 403/404 구분
      });
    }
  }
}

class _RatingsLoading extends StatelessWidget {
  const _RatingsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('평점을 불러오는 중', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _RatingsEmpty extends StatelessWidget {
  const _RatingsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: AppColors.gray),
          SizedBox(height: 12),
          Text('등록된 평점이 없습니다', style: AppTextStyles.bodyMedium),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingsList extends StatelessWidget {
  const _RatingsList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selecting = viewModel.isSelectionMode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // 상단: 기본 = 오른쪽 "편집" / 선택 모드 = 왼쪽 "N개 선택됨" + 오른쪽 "취소"
        SizedBox(
          height: 48,
          child: Row(
            children: [
              if (selecting)
                Text(
                  '${viewModel.selectedRatingIds.length}개 선택됨',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: selecting
                    ? viewModel.exitSelectionMode
                    : viewModel.enterSelectionMode,
                child: Text(
                  selecting ? '취소' : '편집',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (viewModel.message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(viewModel.message!, style: AppTextStyles.bodySmall),
          ),
        for (final entry in viewModel.ratings) ...[
          selecting
              ? _SelectableRatingCard(
                  entry: entry,
                  selected: viewModel.selectedRatingIds.contains(
                    entry.rating.ratingId,
                  ),
                  onTap: () => viewModel.toggleSelection(entry.rating.ratingId),
                )
              : _RatingCard(entry: entry),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.SecondaryScale300, width: 1.5),
);

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: movie == null
                ? Container(
                    width: 82,
                    height: 124,
                    color: AppColors.PrimaryScale200,
                  )
                : TmdbPosterImage(
                    posterPath: movie.posterPath,
                    width: 82,
                    height: 124,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  movie?.title ?? '영화 #${rating.movieId}',
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '별점 ${rating.score} / 5',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (movie == null)
                  const Text('포스터 정보 없음', style: AppTextStyles.bodySmall),
                if (rating.comment != null)
                  Text(
                    rating.comment!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 카드 오른쪽: 개별 수정·삭제
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _SmallButton(
                label: '수정',
                background: AppColors.primaryScale100,
                foreground: AppColors.primary,
                onPressed: () => _onEditPressed(context, rating),
              ),
              const SizedBox(height: 8),
              _SmallButton(
                label: '삭제',
                background: _deleteBackground,
                foreground: _deleteForeground,
                onPressed: () => _onDeletePressed(context, rating),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SelectableRatingCard extends StatelessWidget {
  const _SelectableRatingCard({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final RatingWithMovie entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final title = entry.movie?.title ?? '영화 #${rating.movieId}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.3,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title · 별점 ${rating.score}',
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rating.comment != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      rating.comment!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteSelectedBar extends StatelessWidget {
  const _DeleteSelectedBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            // 1개 이상 선택했을 때만 활성화
            onPressed: count == 0
                ? null
                : () => _onDeleteSelectedPressed(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.PrimaryScale200,
              shape: const StadiumBorder(),
            ),
            child: Text(
              '선택한 $count개 삭제',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
