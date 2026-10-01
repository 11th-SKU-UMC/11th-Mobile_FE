import 'package:flutter/material.dart';

import '../models/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스'];

  Set<String> _selectedGenres = {};

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GenreFilterSheet(
        genres: genres,
        initialSelected: _selectedGenres,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedGenres = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final filteredMovies = _selectedGenres.isEmpty
        ? movies
        : movies.where((m) => _selectedGenres.contains(m.genre)).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '영화',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.violet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search, color: AppColors.black),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _openFilterSheet,
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppColors.violet,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredMovies.isEmpty
                    ? const Center(child: Text('해당 장르의 영화가 없어요.'))
                    : GridView.builder(
                        itemCount: filteredMovies.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, index) {
                          return MovieCard(movie: filteredMovies[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}