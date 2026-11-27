import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/rating_dialog.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/widgets/favorite_button.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  final String movieId; // URL로 받은 TMDB id
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 9주차: 3주차 mock 즐겨찾기 상태(isFavorite)는 제거하고 서버 값을 씁니다.
  @override
  void initState() {
    super.initState();
    // 화면이 처음 만들어질 때 서버의 즐겨찾기 여부를 한 번 조회합니다. (build에서 조회하지 않음)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteDetailViewModel>().load();
    });
  }

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
        title: const Text('영화 상세', style: AppTextStyles.titleAppBar),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TmdbPosterImage(posterPath: movie.posterPath, height: 300),
            const SizedBox(height: 16),
            // 9주차: 제목·정보 텍스트 오른쪽에 즐겨찾기(북마크) 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((movie.releaseDate ?? '').length >= 4)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              movie.releaseDate!.substring(0, 4),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const FavoriteButton(),
                ],
              ),
            ),
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
