import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'tmdb_poster_image.dart';

/// 영화 카드를 누르면 TMDB id를 Path Parameter로 상세 화면에 push합니다.
/// 돌아온 뒤 할 일이 있으면(내 즐겨찾기 갱신 등) [onTap]으로 이동을 직접 처리합니다.
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.width, this.onTap});

  final TmdbMovieDto movie;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseYear;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => context.push('/movies/${movie.id}', extra: movie),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.star),
                const SizedBox(width: 2),
                Text(
                  movie.fiveStarAverage.toStringAsFixed(1),
                  style: AppTextStyles.caption,
                ),
                if (year != null) ...[
                  const SizedBox(width: 6),
                  Text(year, style: AppTextStyles.caption),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 영화 카드 격자 + 하단 footer(더 보기 등)를 한 스크롤로 그립니다.
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    this.physics,
    this.controller,
    this.footer,
  });

  final List<TmdbMovieDto> movies;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;

        return CustomScrollView(
          controller: controller,
          physics: physics,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverGrid.builder(
                itemCount: movies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) =>
                    MovieCard(movie: movies[index]),
              ),
            ),
            if (footer != null) SliverToBoxAdapter(child: footer),
          ],
        );
      },
    );
  }
}
