import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/movie_grid_card.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';
import 'package:movielog/widgets/movie_page_footer.dart';

// 9주차: 5주차의 최대 30개 수집 대신 첫 page만 보여주고 "더 보기"로 한 page씩 추가합니다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final genres = context.watch<MovieListViewModel>().genres;
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        titleStyle: AppTextStyles.titleAppBar,
        actions: [
          // 검색 화면으로 이동 (하단 NavigationBar 없는 화면)
          IconButton(
            tooltip: '영화 검색',
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () => context.push('/movies/search'),
          ),
        ],
      ),
      body: Consumer<PagedMoviesViewModel>(
        builder: (context, vm, child) {
          final firstLoading = vm.phase == LoadPhase.loading;
          return Column(
            children: [
              // 장르 칩 (TMDB Genre API 결과로 구성)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _GenreChip(
                      label: '전체',
                      selected: vm.genreId == null,
                      enabled: !firstLoading,
                      onSelected: () => _selectGenre(vm, null),
                    ),
                    for (final genre in genres)
                      _GenreChip(
                        label: genre.name,
                        selected: vm.genreId == genre.id,
                        enabled: !firstLoading,
                        onSelected: () => _selectGenre(vm, genre.id),
                      ),
                  ],
                ),
              ),
              // 영화 그리드 (상태별 화면)
              Expanded(
                child: switch (vm.phase) {
                  LoadPhase.idle || LoadPhase.loading => const MovieListLoading(),
                  LoadPhase.error => MovieListError(
                    onRetry: () => vm.loadInitial(genreId: vm.genreId),
                  ),
                  LoadPhase.empty => const MovieListEmpty(),
                  LoadPhase.ready => CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid.builder(
                          itemCount: vm.movies.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.55,
                              ),
                          itemBuilder: (context, index) =>
                              MovieGridCard(movie: vm.movies[index]),
                        ),
                      ),
                      // 카드 목록 아래: 더 보기 / 추가 로딩 / 재시도 / 끝
                      SliverToBoxAdapter(child: MoviePageFooter(vm: vm)),
                    ],
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // 장르를 바꾸면 목록·page를 비우고 첫 page부터 다시 불러옵니다.
  void _selectGenre(PagedMoviesViewModel vm, int? genreId) {
    if (vm.genreId == genreId) return; // 같은 장르 다시 누르면 무시
    vm.loadInitial(genreId: genreId);
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primaryScale600,
        backgroundColor: AppColors.primaryScale200,
        disabledColor: AppColors.primaryScale200,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.primaryScale600,
        ),
        // 로딩 중이면 null → Chip 비활성화 (Required 7)
        onSelected: enabled ? (_) => onSelected() : null,
      ),
    );
  }
}
