import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/load_status.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  Future<void> _openFilter(BuildContext context) async {
    final viewModel = context.read<MovieListViewModel>();
    if (!viewModel.canChangeGenre || viewModel.genres.isEmpty) return;

    final selected = await showGenreFilterSheet(
      context,
      genres: viewModel.genres,
      selectedIds: viewModel.selectedGenreIds,
    );
    if (selected == null) return; // 확인을 누르지 않고 닫으면 적용하지 않습니다.
    await viewModel.selectGenres(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) => IconButton(
              tooltip: '장르 필터',
              icon: Badge(
                isLabelVisible: viewModel.selectedGenreIds.length > 1,
                label: Text('${viewModel.selectedGenreIds.length}'),
                child: const Icon(Icons.filter_list),
              ),
              onPressed: viewModel.canChangeGenre && viewModel.genres.isNotEmpty
                  ? () => _openFilter(context)
                  : null,
            ),
          ),
        ],
      ),
      body: const Column(
        children: [
          _GenreChips(),
          Expanded(child: _MovieListBody()),
        ],
      ),
    );
  }
}

/// Genre API의 id/name으로 구성한 장르 Chip입니다.
/// Chip은 한 장르만, 필터 아이콘의 BottomSheet는 여러 장르를 선택합니다.
class _GenreChips extends StatelessWidget {
  const _GenreChips();

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.genres.isEmpty) return const SizedBox(height: 8);

        final selected = viewModel.selectedGenreIds;
        final enabled = viewModel.canChangeGenre;

        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: viewModel.genres.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _GenreChip(
                  label: '전체',
                  selected: selected.isEmpty,
                  onSelected: enabled
                      ? () => viewModel.selectGenres(const [])
                      : null,
                );
              }
              final genre = viewModel.genres[index - 1];
              return _GenreChip(
                label: genre.name,
                selected: selected.contains(genre.id),
                onSelected: enabled
                    ? () => viewModel.selectGenres([genre.id])
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.primary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MovieListBody extends StatelessWidget {
  const _MovieListBody();

  Future<void> _onRefresh(BuildContext context) async {
    final viewModel = context.read<MovieListViewModel>();
    final success = await viewModel.refresh();
    if (success || !context.mounted) return;

    // 새로고침이 실패해도 최근 목록은 유지하고 재시도 여부를 묻습니다.
    final retry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.wifi_off, color: AppColors.error),
        title: const Text('영화 목록을 불러오지 못했어요'),
        content: const Text(
          '네트워크 상태를 확인한 뒤 다시 시도해 주세요.\n지금은 최근에 불러온 목록을 보여드려요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('재시도'),
          ),
        ],
      ),
    );
    if (retry == true && context.mounted) {
      await _onRefresh(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieListViewModel>(
      builder: (context, viewModel, child) {
        return switch (viewModel.status) {
          LoadStatus.idle || LoadStatus.loading => const LoadingView(),
          LoadStatus.error => ErrorView(
            message: viewModel.message,
            onRetry: () => context.read<MovieListViewModel>().reload(),
          ),
          LoadStatus.empty => RefreshIndicator(
            onRefresh: () => _onRefresh(context),
            child: const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [SliverFillRemaining(child: EmptyView())],
            ),
          ),
          LoadStatus.success => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${viewModel.movies.length}편',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _onRefresh(context),
                  child: MovieGrid(
                    movies: viewModel.movies,
                    physics: const AlwaysScrollableScrollPhysics(),
                  ),
                ),
              ),
            ],
          ),
        };
      },
    );
  }
}
