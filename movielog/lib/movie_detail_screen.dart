import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/movie.dart';
import 'package:movielog/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});
  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(widget.movieId))!;

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
      body: Column(
        children: [
          Image.asset(movie.posterAsset, height: 300),
          Text(movie.title, style: const TextStyle(fontSize: 24)),
          // 평균 평점 4.5 (읽기 전용)
          RatingBarIndicator(
            rating: 4.5,
            itemSize: 24,
            itemBuilder: (context, index) =>
                const Icon(Icons.star, color: Colors.amber),
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
                        onPressed: () => Navigator.pop(context),
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
    );
  }
}
