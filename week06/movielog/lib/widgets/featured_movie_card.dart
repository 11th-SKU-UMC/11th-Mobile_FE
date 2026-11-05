import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import 'tmdb_poster_image.dart';

class FeaturedMovieCard extends StatelessWidget {
  const FeaturedMovieCard({super.key, required this.movie});

  final TmdbMovieDto movie;

  // release_date가 null이거나 짧으면 연도를 표시하지 않는다.
  String? get _year {
    final date = movie.releaseDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }

  String get _subtitle {
    final parts = <String>[
      ?_year,
      '★ ${movie.voteAverage.toStringAsFixed(1)}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: double.infinity,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withAlpha(100),
                    AppColors.black.withAlpha(235),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.violet.withAlpha(200),
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.violet),
                      ),
                    ),
                    child: const Text(
                      '추천 신작',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      // TMDB id를 그대로 전달한다. (index 아님)
                      onPressed: () => context.push('/movies/${movie.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.info, color: AppColors.white),
                      label: const Text(
                        '상세보기',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}