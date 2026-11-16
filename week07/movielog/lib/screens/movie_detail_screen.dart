import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/submit_status.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// TMDB 영화 한 편의 상세 화면입니다. 영화 정보는 MovieDetailViewModel.movie에서 읽습니다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _showSnackBar(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  Future<void> _showRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            // Dialog가 이 서버 message를 그대로 보여주고, 입력은 유지합니다.
            throw StateError(viewModel.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );

    // await 뒤에는 반드시 mounted를 다시 확인합니다.
    if (!mounted || saved != true) return;

    _showSnackBar('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;
    final textTheme = Theme.of(context).textTheme;

    final releaseDate = movie.releaseDate;
    final year = (releaseDate != null && releaseDate.length >= 4)
        ? releaseDate.substring(0, 4)
        : null;
    final overview = movie.overview.trim();

    final hasMember = viewModel.memberId != null;
    final canRate =
        hasMember && viewModel.submitStatus != SubmitStatus.submitting;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.violet,
        centerTitle: true,
        title: const Text(
          'Cinema Archive',
          style: TextStyle(
            color: AppColors.violet,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: textTheme.headlineSmall),
                  if (year != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      year,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // TMDB 평균 평점은 10점 만점이라 별 5개 기준으로 환산합니다.
                      RatingBarIndicator(
                        rating: movie.voteAverage / 2,
                        itemCount: 5,
                        itemSize: 24,
                        itemBuilder: (context, index) {
                          return const Icon(
                            Icons.star,
                            color: AppColors.violet,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시놉시스',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overview.isEmpty ? '줄거리 정보가 없습니다.' : overview,
                    style: textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          border: Border(
            top: BorderSide(color: AppColors.gray.withAlpha(60)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 가입 결과의 memberId가 없으면 등록 버튼을 비활성화하고 회원가입으로 안내합니다.
                if (!hasMember)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '평점을 남기려면 먼저 학습용 회원가입이 필요합니다.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: const Text('회원가입'),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleFavorite,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: AppColors.violet,
                          backgroundColor: _isFavorite
                              ? AppColors.violet.withAlpha(30)
                              : Colors.transparent,
                          side: const BorderSide(color: AppColors.violet),
                          shape: const StadiumBorder(),
                        ),
                        icon: Icon(
                          _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: const Text('즐겨찾기'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canRate ? _showRatingDialog : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: AppColors.violet,
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('평점 남기기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
