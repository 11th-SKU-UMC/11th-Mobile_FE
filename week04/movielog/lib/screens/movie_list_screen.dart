import 'package:flutter/material.dart';

import '../models/movie.dart'; // 추가 (Movie 타입 사용)
import '../services/fake_movie_service.dart'; // 추가
import '../theme/app_colors.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../services/genre_preference.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스'];

  Set<String> _selectedGenres = {};
  final FakeMovieService _movieService = const FakeMovieService();
  final GenrePreference _genrePreference = GenrePreference();
  late Future<List<Movie>> _moviesFuture;

  MovieLoadMode _mode = MovieLoadMode.success;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchMovies(mode: _mode);
    _restoreGenres();
  }

  Future<void> _restoreGenres() async {
    final saved = await _genrePreference.read();

    if (!mounted) return; // await 뒤 setState 전에 확인

    setState(() {
      _selectedGenres = saved;
    });
  }

  void _retry() {
    setState(() {
      _mode = MovieLoadMode.success; // 재시도하면 성공하도록 (테스트용)
      _moviesFuture = _movieService.fetchMovies(mode: _mode);
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          GenreFilterSheet(genres: genres, initialSelected: _selectedGenres),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedGenres = result;
    });
     await _genrePreference.save(result);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  icon: const Icon(Icons.filter_list, color: AppColors.violet),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Movie>>(
                  future: _moviesFuture,
                  builder: (context, snapshot) {
                    // 1) 기다리는 중
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const MovieListLoading();
                    }

                    // 2) 오류
                    if (snapshot.hasError) {
                      return MovieListError(onRetry: _retry);
                    }

                    // 3) 서버가 빈 목록을 준 경우
                    final allMovies = snapshot.data ?? const <Movie>[];
                    if (allMovies.isEmpty) {
                      return const MovieListEmpty();
                    }

                    // 4) 장르 필터
                    final filteredMovies = _selectedGenres.isEmpty
                        ? allMovies
                        : allMovies
                              .where((m) => _selectedGenres.contains(m.genre))
                              .toList();

                    if (filteredMovies.isEmpty) {
                      return const Center(child: Text('해당 장르의 영화가 없어요.'));
                    }

                    // 5) 성공
                    return GridView.builder(
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
                    );
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
