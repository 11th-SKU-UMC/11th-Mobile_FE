import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fake_movie_service.dart';
import '../models/movie.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_state_widgets.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() =>
      _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {

    final FakeMovieService _movieService = const FakeMovieService();

    late Future<List<Movie>> _moviesFuture;

    static const String _selectedGenreKey = 'selectedGenre';

    @override
    void initState() {
      super.initState();

      _moviesFuture = _movieService.fetchMovies();
      _loadSelectedGenre();
    }

    Future<void> _loadSelectedGenre() async {
      final prefs = SharedPreferencesAsync();

      final savedGenre =
          await prefs.getString(_selectedGenreKey);

      if (!mounted) {
        return;
      }

      if (savedGenre != null &&
          _genres.contains(savedGenre)) {
        setState(() {
          _selectedGenre = savedGenre;
        });
      }
    }

    Future<void> _saveSelectedGenre(
      String genre,
    ) async {
      final prefs = SharedPreferencesAsync();

      await prefs.setString(
        _selectedGenreKey,
        genre,
      );
    }

    String _selectedGenre = '전체';

    final List<String> _genres = [
      '전체',
      '드라마',
      'SF',
      '로맨스',
    ];

    List<Movie> _filterMovies(List<Movie> movies) {
      if (_selectedGenre == '전체') {
        return movies;
      }

      return movies
          .where(
            (movie) => movie.genre == _selectedGenre,
          )
          .toList();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('영화'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _genres.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 8);
                },
                itemBuilder: (context, index) {
                  final genre = _genres[index];

                  return ChoiceChip(
                    label: Text(genre),
                    selected: _selectedGenre == genre,
                    onSelected: (_) {
                      setState(() {
                        _selectedGenre = genre;
                      });

                      _saveSelectedGenre(genre);
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const MovieListLoading();
                  }

                  if (snapshot.hasError) {
                    return MovieListError(
                      onRetry: () {
                        setState(() {
                          _moviesFuture =
                              _movieService.fetchMovies();
                        });
                      },
                    );
                  }

                  final movies = snapshot.data ?? [];
                  final filteredMovies =
                      _filterMovies(movies);

                  if (filteredMovies.isEmpty) {
                    return const MovieListEmpty();
                  }

                  return MovieGrid(
                    movies: filteredMovies,
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/movies');
                break;
              case 2:
                context.go('/my');
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.movie_outlined),
              selectedIcon: Icon(Icons.movie),
              label: '영화',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '마이',
            ),
          ],
        ),
      );
    }
}