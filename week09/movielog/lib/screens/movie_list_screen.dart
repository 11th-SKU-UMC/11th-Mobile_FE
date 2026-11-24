import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/movie_page_footer.dart';

/// 영화 목록 화면.
/// 9주차: 첫 page만 불러오고, 아래의 "더 보기"로 다음 page를 이어 붙인다.
/// 상태(초기 로딩/추가 로딩/빈 목록/오류/끝)는 PagedMoviesViewModel이 들고 있다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  Future<void> _openFilterSheet() async {
    final vm = context.read<PagedMoviesViewModel>();
    if (vm.isBusy) return;

    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GenreFilterSheet(
        genres: vm.genres,
        initialSelected: vm.selectedGenreIds.toSet(),
      ),
    );

    if (result == null || !mounted) return;
    // 장르를 바꾸면 이전 목록·page·추가 로딩 상태를 비우고 첫 page부터 다시 불러온다.
    vm.applyGenres(result.toList());
  }

  /// 영화의 genre_ids 중 Genre API 목록에서 처음 찾은 장르 이름.
  String? _genreName(List<TmdbGenreDto> genres, TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      for (final genre in genres) {
        if (genre.id == id) return genre.name;
      }
    }
    return null;
  }

  /// 선택된 장르 요약 문구 ("전체" 또는 "액션, 모험")
  String _selectedSummary(PagedMoviesViewModel vm) {
    if (vm.selectedGenreIds.isEmpty) return '전체';
    final names = <String>[];
    for (final id in vm.selectedGenreIds) {
      for (final genre in vm.genres) {
        if (genre.id == id) names.add(genre.name);
      }
    }
    return names.isEmpty ? '전체' : names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '영화',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.violet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    // 검색 화면으로 이동합니다. (/movies/search)
                    onPressed: () => context.push('/movies/search'),
                    icon: const Icon(Icons.search, color: AppColors.black),
                  ),
                ],
              ),
              // 선택된 장르 요약 + 장르 필터 버튼 (첫 로딩 중에는 비활성화)
              Consumer<PagedMoviesViewModel>(
                builder: (context, vm, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedSummary(vm),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: vm.isBusy ? null : _openFilterSheet,
                        icon: Icon(
                          Icons.filter_list,
                          color: vm.isBusy ? AppColors.gray : AppColors.violet,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<PagedMoviesViewModel>(
                  builder: (context, vm, child) {
                    return switch (vm.phase) {
                      LoadPhase.idle ||
                      LoadPhase.loading => const MovieListLoading(),
                      LoadPhase.error => MovieListError(
                          message: vm.errorMessage,
                          onRetry: () => vm.loadInitial(
                            genreIds: vm.selectedGenreIds,
                          ),
                        ),
                      LoadPhase.empty => const MovieListEmpty(),
                      LoadPhase.ready => RefreshIndicator(
                          // 당겨서 새로고침: 현재 장르 그대로 page 1부터 다시 조회
                          onRefresh: () => vm.loadInitial(
                            genreIds: vm.selectedGenreIds,
                          ),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.6,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final movie = vm.movies[index];
                                    return MovieCard(
                                      movie: movie,
                                      genreLabel: _genreName(vm.genres, movie),
                                    );
                                  },
                                  childCount: vm.movies.length,
                                ),
                              ),
                              // 더 보기 / 추가 로딩 / 다음 page 재시도 / 끝 상태
                              SliverToBoxAdapter(child: MoviePageFooter(vm: vm)),
                            ],
                          ),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
