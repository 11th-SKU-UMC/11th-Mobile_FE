import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/genre_bottom_sheet.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movieId,
  });

  final int? movieId;

  @override
  State<MovieDetailScreen> createState() =>
      _MovieDetailScreenState();
}

class _MovieDetailScreenState
    extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;

  Future<void> _showRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) {
        return const RatingDialog();
      },
    );

    if (rating == null) {
      return;
    }

    setState(() {
      _myRating = rating;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '평점 ${rating.toStringAsFixed(1)}점을 남겼습니다.',
        ),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? '즐겨찾기에 추가했습니다.'
              : '즐겨찾기에서 삭제했습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie =
        findMovieById(widget.movieId);

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            '영화를 찾을 수 없습니다.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        title: Text(movie.title),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                movie.posterAsset,
                height: 320,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              movie.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium,
            ),

            const SizedBox(height: 8),

            Text(
              '${movie.genre} · ${movie.year}',
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                _showGenreBottomSheet(movie.genre);
              },
              icon: const Icon(
                Icons.category_outlined,
              ),
              label: const Text(
                '장르 보기',
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '평균 평점',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                RatingBarIndicator(
                  rating: 4.5,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return const Icon(
                      Icons.star,
                      color: Colors.amber,
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text('4.5'),
              ],
            ),

            const SizedBox(height: 24),

            if (_myRating != null) ...[
              Text(
                '내 평점: ${_myRating!.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(
                  Icons.star_outline,
                ),
                label: const Text(
                  '평점 남기기',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenreBottomSheet(String genre) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return GenreBottomSheet(
          genre: genre,
        );
      },
    );
  }
}