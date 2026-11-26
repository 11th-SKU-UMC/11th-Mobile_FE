import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/load_phase.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_page_footer.dart';

/// 영화 목록 화면입니다.
///
/// - 장르 목록·선택: [MovieListViewModel]
/// - 영화 page 목록: [PagedMoviesViewModel] (첫 page만 불러오고 "더 보기"로 이어서 불러옵니다)
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  Future<void> _openFilter(BuildContext context) async {
    final viewModel = context.read<MovieListViewModel>();
    if (!viewModel.canChangeGenre) return;

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
          IconButton(
            tooltip: '영화 검색',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/movies/search'),
          ),
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) => IconButton(
              tooltip: '장르 필터',
              icon: Badge(
                isLabelVisible: viewModel.selectedGenreIds.length > 1,
                label: Text('${viewModel.selectedGenreIds.length}'),
                child: const Icon(Icons.filter_list),
              ),
              onPressed: viewModel.canChangeGenre
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
        final message = viewModel.genreMessage;
        if (message != null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
                TextButton(
                  onPressed: viewModel.retryGenres,
                  child: const Text('장르 다시 불러오기'),
                ),
              ],
            ),
          );
        }
        if (viewModel.genres.isEmpty) return const SizedBox(height: 8);

        final selected = viewModel.selectedGenreIds;
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
                  onSelected: () => viewModel.selectGenres(const []),
                );
              }
              final genre = viewModel.genres[index - 1];
              return _GenreChip(
                label: genre.name,
                selected: selected.contains(genre.id),
                onSelected: () => viewModel.selectGenres([genre.id]),
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
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
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

class _MovieListBody extends StatefulWidget {
  const _MovieListBody();

  @override
  State<_MovieListBody> createState() => _MovieListBodyState();
}

class _MovieListBodyState extends State<_MovieListBody> {
  /// Challenge: 남은 스크롤 거리가 이 값 이하이면 다음 page를 자동으로 불러옵니다.
  static const _loadMoreThreshold = 400.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > _loadMoreThreshold) return;
    final paged = context.read<PagedMoviesViewModel>();
    // 다음 page가 실패한 상태에서는 자동으로 다시 요청하지 않고 재시도 버튼을 기다립니다.
    // 중복 요청 방지(isLoadingMore·hasMore)는 ViewModel이 그대로 처리합니다.
    if (paged.loadMoreError != null) return;
    paged.loadNextPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PagedMoviesViewModel>(
      builder: (context, paged, child) {
        return switch (paged.phase) {
          LoadPhase.idle || LoadPhase.loading => const LoadingView(),
          LoadPhase.error => ErrorView(
            message: paged.errorMessage,
            onRetry: paged.refresh,
          ),
          LoadPhase.empty => RefreshIndicator(
            onRefresh: paged.refresh,
            child: const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [SliverFillRemaining(child: EmptyView())],
            ),
          ),
          LoadPhase.ready => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${paged.movies.length}편 표시 중',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  // 당겨서 새로고침도 조건 변경처럼 첫 page부터 다시 불러옵니다.
                  onRefresh: paged.refresh,
                  child: MovieGrid(
                    movies: paged.movies,
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    footer: MoviePageFooter(vm: paged),
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
