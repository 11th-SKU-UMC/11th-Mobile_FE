import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_card.dart';
import '../widgets/rating_dialog.dart';

/// 마이페이지 → 내가 등록한 평점.
/// root Navigator 위에 push되므로 하단 NavigationBar를 전달하지 않습니다.
/// 7주차 조회 대상은 로그인 사용자가 아니라 가입 결과로 받은 학습용 memberId입니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        final selectedCount = viewModel.selectedRatingIds.length;
        // 목록이 보이는 동안(삭제 중 재조회 포함)에만 하단 삭제 버튼을 보여줍니다.
        final showDeleteBar = viewModel.isSelecting &&
            viewModel.status != MyRatingsLoadStatus.error &&
            viewModel.status != MyRatingsLoadStatus.empty;

        // 다중 삭제 중에는 뒤로가기·스와이프 백을 막고, 끝나면 다시 나갈 수 있습니다.
        return PopScope(
          canPop: !viewModel.isDeletingSelected,
          child: LoadingOverlay(
            isLoading: viewModel.isDeletingSelected,
            child: Scaffold(
              appBar: CommonAppBar(
                title: '내가 등록한 평점',
                centerTitle: true,
                onBack: () {
                  // 앱바의 뒤로가기 버튼은 PopScope를 거치지 않으므로 직접 막습니다.
                  if (viewModel.isDeletingSelected) return;
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/my');
                  }
                },
              ),
              body: SafeArea(child: _buildBody(viewModel)),
              bottomNavigationBar: showDeleteBar
                  ? SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: MovieLogButton(
                          label: '선택한 $selectedCount개 삭제',
                          width: double.infinity,
                          // 선택이 1개 이상일 때만 활성화합니다.
                          onPressed: selectedCount > 0
                              ? () => onDeleteSelectedPressed(context)
                              : null,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(MyRatingsViewModel viewModel) {
    switch (viewModel.status) {
      case MyRatingsLoadStatus.idle:
      case MyRatingsLoadStatus.loading:
        return const MovieListLoading();
      case MyRatingsLoadStatus.error:
        return MovieListError(
          onRetry: viewModel.load,
          // 저장은 성공했는데 목록 재조회만 실패했다면 그 사실을 먼저 알립니다.
          message: viewModel.refreshWarning ?? viewModel.message,
        );
      case MyRatingsLoadStatus.empty:
        return const _EmptyRatings();
      case MyRatingsLoadStatus.success:
        return _RatingList(viewModel: viewModel);
    }
  }
}

class _EmptyRatings extends StatelessWidget {
  const _EmptyRatings();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('아직 등록한 평점이 없습니다.'));
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.message; // 일부 영화 정보 조회 실패·일부 삭제 실패 안내
    final ratings = viewModel.ratings;
    final hasNotice = message != null;
    final isSelecting = viewModel.isSelecting;

    return Column(
      children: [
        _SelectionHeader(viewModel: viewModel),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: ratings.length + (hasNotice ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (hasNotice && index == 0) {
                return Text(message, style: AppTextStyles.bodySmall);
              }
              final entry = ratings[hasNotice ? index - 1 : index];
              final ratingId = entry.rating.ratingId;
              return RatingCard(
                entry: entry,
                // 편집 모드에서는 수정·삭제 버튼 대신 체크박스를 보여줍니다.
                onEdit: isSelecting
                    ? null
                    : () => onEditPressed(context, entry.rating),
                onDelete: isSelecting
                    ? null
                    : () => onDeletePressed(context, entry.rating),
                isSelected: viewModel.selectedRatingIds.contains(ratingId),
                onSelectedChanged: isSelecting
                    ? (_) => viewModel.toggleSelected(ratingId)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 목록 위 한 줄. 기본 모드에서는 오른쪽에 "편집",
/// 편집 모드에서는 왼쪽에 선택한 카드 수, 오른쪽에 "취소"를 보여줍니다.
class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isSelecting = viewModel.isSelecting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          if (isSelecting)
            Text(
              '${viewModel.selectedRatingIds.length}개 선택',
              style: AppTextStyles.bodyMedium,
            ),
          const Spacer(),
          TextButton(
            onPressed: isSelecting
                ? viewModel.cancelSelecting
                : viewModel.startSelecting,
            child: Text(isSelecting ? '취소' : '편집'),
          ),
        ],
      ),
    );
  }
}

/// 수정 버튼: 기존 별점·코멘트가 채워진 RatingDialog를 다시 엽니다.
/// 저장 후 목록은 ViewModel이 다시 조회합니다.
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  // 저장 뒤 목록이 다시 그려져도 쓸 수 있도록 ViewModel을 먼저 잡아 둡니다.
  final viewModel = context.read<MyRatingsViewModel>();

  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 TextField가 빈 칸으로 시작합니다.
      onSubmit: (score, comment) async {
        try {
          await viewModel.updateRating(
            ratingId: rating.ratingId,
            score: score,
            comment: comment, // score와 함께 항상 보내 후기 유지/삭제 의도를 명확히 합니다.
          );
        } on DioException catch (error) {
          // 400/403/404의 서버 message를 Dialog 안에 그대로 보여주고 입력은 유지합니다.
          throw StateError(writeErrorMessage(error));
        }
      },
    ),
  );
}

/// 삭제 버튼: 확인 Dialog를 먼저 열고, 확인했을 때만 삭제 요청을 보냅니다.
/// 단일 삭제는 삭제하는 동안 Dialog가 유지됩니다.
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();

  // 반환값 true는 실제로 삭제까지 마쳤을 때만 나옵니다.
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () async {
        try {
          await viewModel.deleteRating(rating.ratingId);
        } on DioException catch (error) {
          throw StateError(writeErrorMessage(error));
        }
      },
    ),
  );
}

/// 하단 "선택한 N개 삭제" 버튼: 확인 Dialog는 삭제 여부만 묻고 요청 전에 바로 닫힙니다.
/// 이후 삭제는 화면의 ViewModel이 이어받고, 삭제 중에는 로딩 오버레이가 화면을 덮습니다.
Future<void> onDeleteSelectedPressed(BuildContext context) async {
  final viewModel = context.read<MyRatingsViewModel>();
  // 삭제가 끝나 목록이 다시 그려져도 Snackbar를 띄울 수 있게 미리 잡아 둡니다.
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('선택한 평점을 삭제할까요?'),
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

  // 여기서 Dialog는 이미 닫혔습니다. 삭제 요청은 Dialog가 닫힌 뒤에 시작합니다.
  if (confirmed != true) return;

  await viewModel.deleteSelectedRatings();

  // 일부만 실패하면 성공한 항목만 목록에서 사라지고, 실패한 개수를 Snackbar로 알립니다.
  final failed = viewModel.lastDeleteFailedCount;
  if (failed > 0) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.')),
      );
  }
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text('평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _isDeleting ? null : _onConfirm,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }
}
