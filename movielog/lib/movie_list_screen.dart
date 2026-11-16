import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/movie_grid_card.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '영화', titleStyle: AppTextStyles.titleAppBar),
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
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
                      selected: viewModel.selectedGenreId == null,
                      enabled: !viewModel.isLoading,
                      onSelected: () => viewModel.selectGenre(null),
                    ),
                    for (final genre in viewModel.genres)
                      _GenreChip(
                        label: genre.name,
                        selected: viewModel.selectedGenreId == genre.id,
                        enabled: !viewModel.isLoading,
                        onSelected: () => viewModel.selectGenre(genre.id),
                      ),
                  ],
                ),
              ),
              // 영화 그리드 (상태별 화면)
              Expanded(
                child: switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                    onRetry: viewModel.loadInitial,
                  ),
                  MovieListLoadStatus.empty => const MovieListEmpty(),
                  MovieListLoadStatus.success => GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: viewModel.movies.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.55,
                        ),
                    itemBuilder: (context, index) =>
                        MovieGridCard(movie: viewModel.movies[index]),
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
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
