import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/load_status.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'MovieLog', showLogo: true),
      body: Consumer<MovieHomeViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            LoadStatus.idle || LoadStatus.loading => const LoadingView(),
            LoadStatus.error => ErrorView(
              message: viewModel.message,
              onRetry: () => context.read<MovieHomeViewModel>().loadPopular(),
            ),
            LoadStatus.empty => const EmptyView(message: '지금은 인기 영화가 없어요.'),
            LoadStatus.success => _HomeContent(movies: viewModel.popularMovies),
          };
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _HeroBanner(movie: movies.first),
        const SizedBox(height: 24),
        _SectionHeader(
          title: '지금 인기 있는 영화',
          onMore: () => context.go('/movies'),
        ),
        const SizedBox(height: 12),
        _PopularMovieList(movies: movies),
      ],
    );
  }
}

/// 인기 1위 영화를 크게 보여주는 배너입니다.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        // 넓은 화면에서 배너가 지나치게 커지지 않도록 높이를 제한합니다.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TmdbPosterImage(
                  posterPath: movie.backdropPath ?? movie.posterPath,
                  borderRadius: 12,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '인기 1위',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});

  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
          TextButton(onPressed: onMore, child: const Text('전체 보기')),
        ],
      ),
    );
  }
}

class _PopularMovieList extends StatelessWidget {
  const _PopularMovieList({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            MovieCard(movie: movies[index], width: 130),
      ),
    );
  }
}
