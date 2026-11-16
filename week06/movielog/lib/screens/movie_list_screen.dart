import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/tab_app_bar.dart';

/// 영화 목록 탭.
///
/// 상태와 API 호출은 [MovieListViewModel]이 맡고, 이 화면은 상태를 그리기만 한다.
/// - 장르 칩은 TMDB Genre API 결과로 만들고, 고르면 ViewModel이 `with_genres`로 다시 요청한다.
/// - Loading·Empty·Error·Success 네 상태를 각각 다른 Widget으로 보여준다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  /// push: 목록을 Stack에 남겨서 상세에서 뒤로 가면 같은 장르의 목록으로 돌아온다.
  /// URL에는 TMDB id를, extra에는 화면에 그릴 DTO를 담는다.
  void _openDetail(BuildContext context, TmdbMovieDto movie) {
    context.push(AppRoutes.movieDetail(movie.id), extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TabAppBar(title: '영화'),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          // 칩 영역과 목록 영역을 각각 Consumer로 감싸 필요한 부분만 다시 그린다.
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) => GenreFilterChips(
              genres: viewModel.genres,
              selectedGenreId: viewModel.selectedGenreId,
              // 요청 중에는 장르를 바꾸지 못하게 막는다.
              enabled: !viewModel.isLoading,
              onSelected: (genreId) =>
                  context.read<MovieListViewModel>().selectGenre(genreId),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                    message: viewModel.message ?? '영화를 불러오지 못했어요.',
                    onRetry: () => context.read<MovieListViewModel>().retry(),
                  ),
                  MovieListLoadStatus.empty => _buildEmpty(context, viewModel),
                  MovieListLoadStatus.success => MovieGrid(
                    movies: viewModel.movies,
                    genreNameOf: viewModel.genreNameOf,
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

  Widget _buildEmpty(BuildContext context, MovieListViewModel viewModel) {
    final filtered = viewModel.selectedGenreId != null;

    return MovieListEmpty(
      message: filtered ? '이 장르의 영화가 없어요.' : '아직 등록된 영화가 없어요.',
      actionLabel: filtered ? '전체 영화 보기' : null,
      onAction: filtered
          ? () => context.read<MovieListViewModel>().selectGenre(null)
          : null,
    );
  }
}
