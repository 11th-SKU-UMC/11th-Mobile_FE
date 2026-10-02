import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String _selectedGenre = '전체';

  final genres = const ['전체', '드라마', 'SF', '애니메이션'];

  List<Movie> get filteredMovies {
    if (_selectedGenre == '전체') {
      return movies;
    }

    return movies.where((movie) => movie.genre == _selectedGenre).toList();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: genres.map((genre) {
              return ListTile(
                title: Text(genre),
                trailing: genre == _selectedGenre
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  Navigator.pop(context, genre);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedGenre = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredMovies;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('영화'),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = genres[index];

                return ChoiceChip(
                  label: Text(genre),
                  selected: _selectedGenre == genre,
                  onSelected: (_) {
                    setState(() {
                      _selectedGenre = genre;
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final movie = list[index];

                return MovieCard(
                  movie: movie,
                  onTap: () {
                    context.push('/movies/${movie.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
