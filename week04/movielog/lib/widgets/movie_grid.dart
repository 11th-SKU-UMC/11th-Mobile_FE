import 'package:flutter/material.dart';

import '../data/movie.dart';
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
///
/// 내용이 적어도 항상 스크롤되게 해서, 바깥의 RefreshIndicator로 당겨서 새로고침할 수 있게 한다.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies, required this.onMovieTap});

  final List<Movie> movies;
  final ValueChanged<Movie> onMovieTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: movieGridPadding,
      itemCount: movies.length,
      gridDelegate: movieGridDelegate,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(movie: movie, onTap: () => onMovieTap(movie));
      },
    );
  }
}
