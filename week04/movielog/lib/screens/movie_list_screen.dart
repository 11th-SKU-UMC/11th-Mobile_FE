import 'dart:async';

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    this.movieService = const FakeMovieService(),
    this.genrePreference,
  });

  final FakeMovieService movieService;
  final GenrePreference? genrePreference;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['전체', '드라마', 'SF', '애니메이션'];

  late final GenrePreference _genrePreference;
  late Future<List<Movie>> _moviesFuture;

  String _selectedGenre = GenrePreference.defaultGenre;
  MovieLoadMode _loadMode = MovieLoadMode.success;

  @override
  void initState() {
    super.initState();
    _genrePreference = widget.genrePreference ?? GenrePreference();

    // Future는 build가 아니라 initState에서 한 번만 생성한다.
    _moviesFuture = _loadMovies();
    _restoreSelectedGenre();
  }

  Future<List<Movie>> _loadMovies() async {
    try {
      return await widget.movieService.fetchMovies(mode: _loadMode);
    } on MovieLoadException catch (error, stackTrace) {
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 로드 시도 종료 (mode: ${_loadMode.name})');
    }
  }

  Future<void> _restoreSelectedGenre() async {
    try {
      final savedGenre = await _genrePreference.read();

      // await 사이에 화면이 사라졌다면 setState를 호출하지 않는다.
      if (!mounted) return;
      if (!genres.contains(savedGenre)) return;

      setState(() {
        _selectedGenre = savedGenre;
      });
    } catch (error) {
      debugPrint('저장된 장르 복원 실패: $error');
    }
  }

  void _selectGenre(String genre) {
    if (genre == _selectedGenre) return;

    setState(() {
      _selectedGenre = genre;
    });

    unawaited(
      _genrePreference.save(genre).catchError((Object error) {
        debugPrint('장르 저장 실패: $error');
      }),
    );
  }

  void _retry() {
    setState(() {
      // 재시도 시에는 정상 응답을 받는 상황을 가정한다.
      _loadMode = MovieLoadMode.success;
      _moviesFuture = _loadMovies();
    });
  }

  void _changeLoadMode(MovieLoadMode mode) {
    setState(() {
      _loadMode = mode;
      _moviesFuture = _loadMovies();
    });
  }

  List<Movie> _filterByGenre(List<Movie> movies) {
    if (_selectedGenre == GenrePreference.defaultGenre) {
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

    if (!mounted) return;

    if (result != null) {
      _selectGenre(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('영화'),
        actions: [
          PopupMenuButton<MovieLoadMode>(
            tooltip: '로드 모드 (테스트용)',
            icon: const Icon(Icons.science_outlined),
            initialValue: _loadMode,
            onSelected: _changeLoadMode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: MovieLoadMode.success, child: Text('성공')),
              PopupMenuItem(value: MovieLoadMode.empty, child: Text('빈 목록')),
              PopupMenuItem(value: MovieLoadMode.failure, child: Text('실패')),
            ],
          ),
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
                  onSelected: (_) => _selectGenre(genre),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                final movies = _filterByGenre(snapshot.data ?? const <Movie>[]);

                if (movies.isEmpty) {
                  return const MovieListEmpty();
                }

                return MovieGrid(movies: movies);
              },
            ),
          ),
        ],
      ),
    );
  }
}
