import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_spacing.dart';
import 'movie_card.dart';

/// 영화 목록 Grid와 Loading Skeleton이 같은 배치를 쓰도록 한곳에 둔다.
const EdgeInsets movieGridPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.sm,
  AppSpacing.md,
  AppSpacing.lg,
);

const SliverGridDelegateWithFixedCrossAxisCount movieGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md - 4,
      mainAxisSpacing: AppSpacing.lg,
      childAspectRatio: 0.56,
    );

/// 영화 카드 2열 Grid. (Success 상태)
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    required this.onMovieTap,
    this.genreNameOf,
  });

  final List<TmdbMovieDto> movies;
  final ValueChanged<TmdbMovieDto> onMovieTap;

  /// 카드에 보여줄 대표 장르 이름을 고른다. null이면 장르를 표시하지 않는다.
  final String? Function(TmdbMovieDto movie)? genreNameOf;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: movieGridPadding,
      itemCount: movies.length,
      gridDelegate: movieGridDelegate,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(
          movie: movie,
          genreName: genreNameOf?.call(movie),
          onTap: () => onMovieTap(movie),
        );
      },
    );
  }
}
