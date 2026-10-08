import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;

  Future<void> _openRatingDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) {
        return const MovieRatingInput();
      },
    );

    if (result != null) {
      setState(() {
        _myRating = result;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('평점 $_myRating점을 저장했습니다.')));
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(movie.title),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Image.asset(
                  movie.posterAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.movie, size: 80));
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              movie.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text('${movie.genre} · ${movie.year}'),

            const SizedBox(height: 20),

            const Text('평균 평점', style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            Row(
              children: [
                RatingBarIndicator(
                  rating: 4.5,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, _) {
                    return const Icon(Icons.star, color: Colors.amber);
                  },
                ),
                const SizedBox(width: 8),
                const Text('4.5'),
              ],
            ),

            const SizedBox(height: 20),

            Text(movie.description),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openRatingDialog,
                child: Text(_myRating == null ? '평점 남기기' : '내 평점: $_myRating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
