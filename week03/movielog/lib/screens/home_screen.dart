import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/movie.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/featured_movie_card.dart';
import '../widgets/movie_card.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _popularCardWidth = 140;
  static const double _popularListHeight = 270;

  /// push: 홈을 Stack에 남긴 채 상세를 위에 쌓는다. 상세에서 뒤로 가면 홈으로 돌아온다.
  void _openDetail(BuildContext context, Movie movie) {
    context.push(AppRoutes.movieDetail(movie.id));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final featured = findMovieById(featuredMovieId) ?? movies.first;
    final popular = [...movies]
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));

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
      ),
    );
  }

  void _showNotReady(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('검색은 아직 준비 중이에요.')));
  }
}
