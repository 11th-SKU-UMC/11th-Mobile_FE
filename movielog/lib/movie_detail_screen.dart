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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
        ),
      );
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
    final hasMember = context.select<MovieDetailViewModel, bool>(
      (vm) => vm.memberId != null,
    );

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
            ElevatedButton(
              onPressed: hasMember ? _openRatingDialog : null,
              child: const Text('평점 남기기'),
            ),
            // 학습용 회원이 없으면 등록 버튼 비활성화 + 가입 안내
            if (!hasMember)
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('학습용 회원가입 후 평점을 남길 수 있어요 →'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
