import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/rating_dialog.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  final String movieId; // URL로 받은 TMDB id
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  Future<void> _openRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();
    String? lastError;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것 차단
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            lastError = viewModel.submitMessage ?? '저장에 실패했습니다.';
            throw StateError(lastError!);
          }
        },
      ),
    );

    if (!mounted) return; // await 뒤에는 mounted 재확인
    if (saved == true) {
      final snackBar = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('평점을 등록했습니다.'),
          action: SnackBarAction(
            label: '내 평점 보기',
            onPressed: () => context.push('/my/ratings'),
          ),
        ),
      );
      // 버튼(action)이 있는 SnackBar는 최신 Flutter에서 자동으로 닫히지 않아서 4초 뒤 직접 닫습니다.
      Future.delayed(const Duration(seconds: 4), snackBar.close);
    } else if (lastError != null) {
      // 실패 후 취소한 경우
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('평점을 등록하지 못했습니다. $lastError')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화 정보를 불러올 수 없어요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
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
            // 8주차: 보호 화면은 Router가 signedIn일 때만 보여주므로 memberId 확인이 필요 없습니다.
            ElevatedButton(
              onPressed: _openRatingDialog,
              child: const Text('평점 남기기'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
