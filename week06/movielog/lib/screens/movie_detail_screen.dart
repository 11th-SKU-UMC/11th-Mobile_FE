import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../models/movie_rating.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key});

  Future<void> _showRatingDialog(
    BuildContext context,
    MovieDetailViewModel viewModel,
  ) async {
    final rating = await showDialog<MovieRating>(
      context: context,
      builder: (context) => RatingDialog(
        movieId: viewModel.movieId,
        initialRating: viewModel.myRating?.score ?? 3,
      ),
    );
    if (!context.mounted || rating == null) return;
    viewModel.setRating(rating);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('내 평점 ${rating.score.toStringAsFixed(1)}점을 반영했어요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/movies'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('MovieLog'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<MovieDetailViewModel>(
          builder: (context, viewModel, child) {
            final movie = viewModel.movie;
            if (movie == null) {
              return viewModel.status == MovieDetailLoadStatus.error
                  ? MovieListError(
                      message: viewModel.message ?? '영화를 찾을 수 없어요.',
                      onRetry: viewModel.loadMovie,
                    )
                  : const MovieListLoading();
            }
            return _buildDetails(context, viewModel, movie);
          },
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    MovieDetailViewModel viewModel,
    TmdbMovieDto movie,
  ) {
    final colors = Theme.of(context).colorScheme;
    final year = movie.releaseDate?.split('-').first ?? '';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (viewModel.status == MovieDetailLoadStatus.loading)
            const LinearProgressIndicator(),
          if (viewModel.status == MovieDetailLoadStatus.error)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(viewModel.message ?? '상세 정보를 불러오지 못했어요.'),
                  ),
                  TextButton(
                    onPressed: viewModel.loadMovie,
                    child: const Text('재시도'),
                  ),
                ],
              ),
            ),
          AspectRatio(
            aspectRatio: 0.68,
            child: LayoutBuilder(
              builder: (context, constraints) => TmdbPosterImage(
                posterPath: movie.posterPath,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontSize: 24),
                ),
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(year, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RatingBarIndicator(
                      rating: movie.voteAverage / 2,
                      itemCount: 5,
                      itemSize: 19,
                      unratedColor: colors.outline.withValues(alpha: 0.35),
                      itemBuilder: (context, _) =>
                          Icon(Icons.star, color: colors.primary),
                    ),
                    Text('TMDB ${movie.voteAverage.toStringAsFixed(1)} / 10'),
                    if (viewModel.myRating != null)
                      Text(
                        '내 평점 ${viewModel.myRating!.score.toStringAsFixed(1)} / 5',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (movie.genres.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final genre in movie.genres)
                        Chip(label: Text(genre.name)),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),
                Text('시놉시스', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  movie.overview.trim().isEmpty
                      ? '줄거리 정보가 없어요.'
                      : movie.overview,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: viewModel.toggleFavorite,
                        icon: Icon(
                          viewModel.isFavorite
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        label: Text(viewModel.isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showRatingDialog(context, viewModel),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: Text(
                          viewModel.myRating == null ? '평점 남기기' : '평점 수정',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
