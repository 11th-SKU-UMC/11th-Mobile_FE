import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/tmdb_poster_image.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _openMovie(
    BuildContext context,
    FavoritesViewModel viewModel,
    FavoriteListItem item,
  ) async {
    await context.push('/movies/${item.favorite.movieId}', extra: item.movie);
    if (context.mounted) await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavoritesViewModel>();
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 즐겨찾기',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: SafeArea(
        child: switch (viewModel.phase) {
          LoadPhase.idle || LoadPhase.loading => const MovieListLoading(),
          LoadPhase.error => MovieListError(
            message: viewModel.errorMessage!,
            onRetry: viewModel.refresh,
          ),
          LoadPhase.empty => RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('아직 즐겨찾기한 영화가 없습니다.')),
                ),
              ],
            ),
          ),
          LoadPhase.ready => RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
                childAspectRatio: 0.54,
              ),
              itemCount: viewModel.items.length,
              itemBuilder: (context, index) {
                final item = viewModel.items[index];
                final movieId = item.favorite.movieId;
                final movie = item.movie;
                void open() => _openMovie(context, viewModel, item);
                return Column(
                  key: ValueKey(movieId),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: movie == null
                          ? InkWell(
                              onTap: open,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) =>
                                          TmdbPosterImage(
                                            posterPath: null,
                                            width: constraints.maxWidth,
                                            height: constraints.maxHeight,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('영화 #$movieId'),
                                ],
                              ),
                            )
                          : MovieCard(
                              movie: movie,
                              genres: movie.genres,
                              onTap: open,
                            ),
                    ),
                    if (movie?.posterPath?.isNotEmpty != true)
                      TextButton(
                        onPressed: viewModel.canRetryMovie(movieId)
                            ? () => viewModel.retryMovie(movieId)
                            : null,
                        child: Text(
                          viewModel.isRetrying(movieId)
                              ? '조회 중'
                              : '영화 정보 다시 조회',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        },
      ),
    );
  }
}
