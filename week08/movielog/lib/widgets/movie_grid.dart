import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies, this.genres = const []});

  final List<TmdbMovieDto> movies;
  final List<TmdbGenreDto> genres;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 18,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) =>
          MovieCard(movie: movies[index], genres: genres),
    );
  }
}
