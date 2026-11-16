import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import 'tmdb_poster_image.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.genres = const []});

  final TmdbMovieDto movie;
  final List<TmdbGenreDto> genres;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.split('-').first ?? '';
    final names = genres
        .where((genre) => movie.genreIds.contains(genre.id))
        .map((genre) => genre.name)
        .join(', ');
    final metadata = [
      if (year.isNotEmpty) year,
      if (names.isNotEmpty) names,
    ].join(' · ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => TmdbPosterImage(
                      posterPath: movie.posterPath,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '★ ${movie.voteAverage.toStringAsFixed(1)} / 10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (metadata.isNotEmpty)
            Text(
              metadata,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
