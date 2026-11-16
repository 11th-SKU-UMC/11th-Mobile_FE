import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/movie_rating_input.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  final String movieId; // URL로 받은 TMDB id
  final TmdbMovieDto? movie; // 카드에서 extra로 넘겨준 영화 정보

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    // 영화 정보 없이 들어온 경우 (앱 꺼짐 방지)
    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화 정보를 불러올 수 없어요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          // 즐겨찾기
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isFavorite ? '즐겨찾기 추가' : '즐겨찾기 삭제')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TmdbPosterImage(posterPath: movie.posterPath, height: 300),
            Text(movie.title, style: const TextStyle(fontSize: 24)),
            // TMDB 평균 평점 (10점 만점 → 별 5개로 변환)
            RatingBarIndicator(
              rating: movie.voteAverage / 2,
              itemSize: 24,
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                movie.overview.isEmpty ? '줄거리 정보가 없어요.' : movie.overview,
                textAlign: TextAlign.center,
              ),
            ),
            // 평점 남기기 → Dialog
            ElevatedButton(
              child: const Text('평점 남기기'),
              onPressed: () {
                double rating = 3;
                showDialog(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setDialogState) => AlertDialog(
                      title: const Text('평점 남기기'),
                      content: MovieRatingInput(
                        rating: rating,
                        onChanged: (value) =>
                            setDialogState(() => rating = value),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // 이후 평점 API에 movieId로 보낼 값
                            debugPrint(
                              '[평점] movieId=${movie.id}, score=$rating',
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
