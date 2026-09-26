import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/genre_filter_sheet.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  Set<String> _selectedGenres = {};

  List<Movie> get _filteredMovies {
    if (_selectedGenres.isEmpty) return movies;
    return movies
        .where((movie) => _selectedGenres.contains(movie.genre))
        .toList();
  }

  List<String> get _genres {
    return {for (final movie in movies) movie.genre}.toList();
  }

  Future<void> _showGenreFilter() async {
    final selectedGenres = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          GenreFilterSheet(genres: _genres, initialGenres: _selectedGenres),
    );

    if (selectedGenres == null || !mounted) return;
    setState(() => _selectedGenres = selectedGenres);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            onPressed: _showGenreFilter,
            tooltip: '장르 필터',
            icon: Badge(
              isLabelVisible: _selectedGenres.isNotEmpty,
              child: Icon(
                _selectedGenres.isEmpty
                    ? Icons.filter_alt_outlined
                    : Icons.filter_alt,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _filteredMovies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 18,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (context, index) {
            return _MovieGridCard(movie: _filteredMovies[index]);
          },
        ),
      ),
    );
  }
}

class _MovieGridCard extends StatelessWidget {
  const _MovieGridCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
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
                        '★ ${movie.rating.toStringAsFixed(1)}',
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
          Text(
            '${movie.year} · ${movie.genre}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
