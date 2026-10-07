import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();
  late Future<List<Movie>> _moviesFuture;
  String _selectedGenre = '전체';
  bool _savingGenre = false;
  static const _genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadInitialData();
  }

  Future<List<Movie>> _loadInitialData() async {
    final moviesFuture = _loadMovies(MovieLoadMode.success);
    final genreFuture = _readGenre();
    await Future.wait<Object>([moviesFuture, genreFuture]);
    final savedGenre = await genreFuture;
    if (mounted) {
      _selectedGenre = _genres.contains(savedGenre) ? savedGenre : '전체';
    }
    return await moviesFuture;
  }

  Future<String> _readGenre() async {
    try {
      return await _genrePreference.read();
    } catch (error, stackTrace) {
      debugPrint('장르 설정 읽기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      return '전체';
    }
  }

  Future<List<Movie>> _loadMovies(MovieLoadMode mode) async {
    try {
      return await _movieService.fetchMovies(mode: mode);
    } on MovieLoadException catch (error, stackTrace) {
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 로드 시도 종료');
    }
  }

  void _retry() {
    setState(() {
      _moviesFuture = _loadMovies(MovieLoadMode.success);
    });
  }

  Future<void> _selectGenre(String genre) async {
    if (_savingGenre || genre == _selectedGenre) return;
    final previousGenre = _selectedGenre;
    setState(() {
      _selectedGenre = genre;
      _savingGenre = true;
    });
    try {
      await _genrePreference.save(genre);
    } catch (error, stackTrace) {
      debugPrint('장르 설정 저장 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _selectedGenre = previousGenre);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장르를 저장하지 못했습니다. 다시 선택해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _savingGenre = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '영화'),
      body: SafeArea(
        child: FutureBuilder<List<Movie>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.none ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const MovieListLoading();
            }
            if (snapshot.hasError) {
              return MovieListError(onRetry: _retry);
            }
            final loadedMovies = snapshot.data ?? const <Movie>[];
            final filteredMovies = _selectedGenre == '전체'
                ? loadedMovies
                : loadedMovies
                      .where((movie) => movie.genre == _selectedGenre)
                      .toList();
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      for (final genre in _genres)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(genre),
                            selected: _selectedGenre == genre,
                            onSelected: _savingGenre
                                ? null
                                : (_) => _selectGenre(genre),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredMovies.isEmpty
                      ? const MovieListEmpty()
                      : MovieGrid(movies: filteredMovies),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
