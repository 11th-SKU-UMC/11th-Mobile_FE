import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

import 'package:provider/provider.dart';

import '../view_models/movie_detail_view_model.dart';
import '../view_models/signup_view_model.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movieId,
    required this.movie,
  });

  final int? movieId;
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;

  Future<void> _showRatingDialog() async {
    final viewModel =
        context.read<MovieDetailViewModel>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(
            score: score,
            comment: comment,
          );

          if (viewModel.submitStatus !=
              SubmitStatus.success) {
            throw StateError(
              viewModel.submitMessage ??
                  '저장에 실패했습니다.',
            );
          }
        },
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('평점이 등록되었습니다.'),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화 정보를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 420,
                width: double.infinity,
                child: TmdbPosterImage(posterPath: movie.posterPath),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              movie.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              movie.releaseDate?.isNotEmpty == true
                  ? movie.releaseDate!
                  : '개봉일 정보 없음',
            ),
            const SizedBox(height: 20),
            Text(movie.overview.isEmpty ? '줄거리 정보가 없습니다.' : movie.overview),
            const SizedBox(height: 24),
            const Text(
              'TMDB 평점',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                RatingBarIndicator(
                  rating: movie.voteAverage / 2,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (_, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                Text(movie.voteAverage.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 24),
          
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.star_outline),
                label: const Text('평점 남기기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
