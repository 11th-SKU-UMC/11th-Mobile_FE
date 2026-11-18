import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'MovieLog'),
      body: SafeArea(
        child: Consumer<MovieHomeViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MovieHomeLoadStatus.idle ||
              MovieHomeLoadStatus.loading => const MovieListLoading(),
              MovieHomeLoadStatus.error => MovieListError(
                message: viewModel.message ?? '인기 영화를 불러오지 못했어요.',
                onRetry: viewModel.loadPopular,
              ),
              MovieHomeLoadStatus.empty => const Center(
                child: Text('인기 영화가 없어요.'),
              ),
              MovieHomeLoadStatus.success => ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    '오늘은 어떤\n영화를 볼까요?',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 26, height: 1.25),
                  ),
                  const SizedBox(height: 20),
                  _FeaturedMovieCard(movie: viewModel.popularMovies.first),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '인기 영화',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/movies'),
                        child: const Text('전체보기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 270,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.popularMovies.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _PopularMovieCard(
                        movie: viewModel.popularMovies[index],
                      ),
                    ),
                  ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

class _FeaturedMovieCard extends StatelessWidget {
  const _FeaturedMovieCard({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => context.push('/movies/${movie.id}', extra: movie),
        child: SizedBox(
          height: 360,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: 360,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '오늘의 인기 영화',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      movie.releaseDate?.split('-').first ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/movies/${movie.id}', extra: movie),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('상세보기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularMovieCard extends StatelessWidget {
  const _PopularMovieCard({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.split('-').first ?? '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: 140,
                height: 195,
              ),
            ),
            const SizedBox(height: 8),
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (year.isNotEmpty)
              Text(
                year,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              'TMDB ${movie.voteAverage.toStringAsFixed(1)} / 10',
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
