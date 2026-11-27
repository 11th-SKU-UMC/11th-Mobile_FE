import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/tab_app_bar.dart';

/// 영화 목록 탭.
///
/// 5주차의 "Discover 최대 30개 수집" 대신 첫 page만 보여주고, "더 보기"로 다음 page를 이어 붙인다.
/// 상태와 API 호출은 [PagedMoviesViewModel]이 맡고, 이 화면은 상태를 그리기만 한다.
/// - 장르 칩을 바꾸면 이전 목록을 비우고 첫 page부터 다시 불러온다.
/// - 앱바 오른쪽 검색 아이콘으로 검색 화면(`/movies/search`)에 간다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  /// push: 목록을 Stack에 남겨서 상세에서 뒤로 가면 같은 장르·같은 page의 목록으로 돌아온다.
  void _openDetail(BuildContext context, TmdbMovieDto movie) {
    context.push(AppRoutes.movieDetail(movie.id), extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '영화 검색',
            onPressed: () => context.push(AppRoutes.movieSearch),
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Consumer<PagedMoviesViewModel>(
            builder: (context, viewModel, child) => GenreFilterChips(
              genres: viewModel.genres,
              selectedGenreId: viewModel.genreId,
              // 요청 중에도 바꿀 수 있다. 이전 장르의 늦은 응답은 ViewModel이 버린다.
              onSelected: (genreId) {
                final vm = context.read<PagedMoviesViewModel>();
                if (genreId != vm.genreId || vm.phase != LoadPhase.ready) {
                  vm.loadInitial(genreId: genreId);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.phase) {
                  LoadPhase.idle ||
                  LoadPhase.loading => const MovieListLoading(),
                  LoadPhase.error => MovieListError(
                    message:
                        viewModel.errorMessage ??
                        PagedMoviesViewModel.listFailedMessage,
                    onRetry: viewModel.retryInitial,
                  ),
                  LoadPhase.empty => _buildEmpty(context, viewModel),
                  LoadPhase.ready => _PagedMovieGrid(
                    viewModel: viewModel,
                    onMovieTap: (movie) => _openDetail(context, movie),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, PagedMoviesViewModel viewModel) {
    final filtered = viewModel.genreId != null;

    return MovieListEmpty(
      message: filtered ? '이 장르의 영화가 없어요.' : '아직 등록된 영화가 없어요.',
      actionLabel: filtered ? '전체 영화 보기' : null,
      onAction: filtered
          ? () => context.read<PagedMoviesViewModel>().loadInitial()
          : null,
    );
  }
}

/// 기존 영화 카드 Grid 아래에 [MoviePageFooter]를 붙인다.
class _PagedMovieGrid extends StatelessWidget {
  const _PagedMovieGrid({required this.viewModel, required this.onMovieTap});

  final PagedMoviesViewModel viewModel;
  final ValueChanged<TmdbMovieDto> onMovieTap;

  @override
  Widget build(BuildContext context) {
    final movies = viewModel.movies;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: movieGridPadding,
          sliver: SliverGrid.builder(
            gridDelegate: movieGridDelegate,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                key: ValueKey(movie.id),
                movie: movie,
                genreName: viewModel.genreNameOf(movie),
                onTap: () => onMovieTap(movie),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: MoviePageFooter(vm: viewModel)),
      ],
    );
  }
}
