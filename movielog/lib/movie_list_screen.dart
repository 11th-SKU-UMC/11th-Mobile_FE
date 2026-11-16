import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';
import 'package:movielog/widgets/movie_list_empty.dart';

import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';

import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/movie.dart';
import 'package:movielog/movie_grid_card.dart';

import 'package:movielog/services/fake_movie_service.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스'];
  String selectedGenre = '전체';
  final _movieService = const FakeMovieService();
  late Future<List<Movie>> _moviesFuture;
  final _genrePreference = GenrePreference();

  // 4주차, 화면이 처음 한 번 만들어질 때 진동벨 받아두는 거.
  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchMovies();
    _loadSavedGenre();
  }

  void _retry() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies();
    });
  }

  Future<void> _loadSavedGenre() async {
    final savedGenre = await _genrePreference.read();

    if (!mounted) return;

    setState(() {
      selectedGenre = savedGenre;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '영화', titleStyle: AppTextStyles.titleAppBar),
      body: Column(
        children: [
          // 장르 칩 (가로 스크롤)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final genre in genres) ...[
                  ChoiceChip(
                    label: Text(genre),
                    selected: selectedGenre == genre,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryScale600,
                    backgroundColor: AppColors.primaryScale200,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selectedGenre == genre
                          ? Colors.white
                          : AppColors.primaryScale600,
                    ),
                    onSelected: (_) async {
                      setState(() {
                        selectedGenre = genre;
                      });
                      await _genrePreference.save(genre);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          // 영화 그리드
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                // 1. 아직 기다리는 중이면 로딩 동그라미
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                // 2. 받아온 영화 꺼내기 (없으면 빈 목록)
                final loadedMovies = snapshot.data ?? const <Movie>[];

                // 3. 선택된 장르로 거르기 (D에서 지운 코드가 여기로 이사 옴)
                final filteredMovies = selectedGenre == '전체'
                    ? loadedMovies
                    : loadedMovies
                          .where((movie) => movie.genre == selectedGenre)
                          .toList();

                if (filteredMovies.isEmpty) {
                  // ← 여기로 이사
                  return const MovieListEmpty();
                }

                // 4. 기존 그리드 그대로
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMovies.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.55,
                  ),
                  itemBuilder: (context, index) {
                    return MovieGridCard(movie: filteredMovies[index]);
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
