import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/featured_movie_card.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _popularCardWidth = 140;
  static const double _popularListHeight = 270;

  /// Loading·Empty·Error 안내가 차지하는 높이. (ListView 안이라 높이를 정해줘야 한다)
  static const double _statusHeight = 320;

  /// push: 홈을 Stack에 남긴 채 상세를 위에 쌓는다. 상세에서 뒤로 가면 홈으로 돌아온다.
  /// URL에는 TMDB id를, extra에는 화면에 그릴 DTO를 담는다.
  void _openDetail(BuildContext context, TmdbMovieDto movie) {
    context.push(AppRoutes.movieDetail(movie.id), extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: TabAppBar(
        title: 'MovieLog',
        actions: [
          IconButton(
            tooltip: '검색',
            onPressed: () => _showNotReady(context),
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 인기 영화 상태가 바뀌면 이 영역만 다시 그린다.
          Consumer<MovieHomeViewModel>(
            builder: (context, viewModel, child) {
              return switch (viewModel.status) {
                MovieHomeLoadStatus.idle ||
                MovieHomeLoadStatus.loading => const SizedBox(
                  height: _statusHeight,
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: '인기 영화를 불러오는 중',
                    ),
                  ),
                ),
                MovieHomeLoadStatus.error => SizedBox(
                  height: _statusHeight,
                  child: MovieListError(
                    message: viewModel.message ?? '인기 영화를 불러오지 못했어요.',
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  ),
                ),
                MovieHomeLoadStatus.empty => const SizedBox(
                  height: _statusHeight,
                  child: MovieListEmpty(message: '지금은 인기 영화가 없어요.'),
                ),
                MovieHomeLoadStatus.success => _buildPopular(
                  context,
                  viewModel.popularMovies,
                ),
              };
            },
          ),
        ],
      ),
    );
  }

  /// Popular 앞 5개. 1위는 추천 카드로 크게, 5개 전체는 가로 목록으로 보여준다.
  Widget _buildPopular(BuildContext context, List<TmdbMovieDto> popular) {
    final featured = popular.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: FeaturedMovieCard(
            movie: featured,
            onTap: () => _openDetail(context, featured),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(
            title: '인기 영화',
            actionLabel: '전체보기',
            // go: 영화 탭으로 위치 자체를 바꾼다(탭 전환).
            onActionPressed: () => context.go(AppRoutes.movies),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: _popularListHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: popular.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md - 4),
            itemBuilder: (context, index) {
              final movie = popular[index];
              return SizedBox(
                width: _popularCardWidth,
                child: MovieCard(
                  movie: movie,
                  onTap: () => _openDetail(context, movie),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNotReady(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('검색은 아직 준비 중이에요.')));
  }
}
