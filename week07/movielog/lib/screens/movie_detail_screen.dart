import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/load_status.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_rating_input.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key});

  void _toggleFavorite(BuildContext context) {
    final added = context.read<MovieDetailViewModel>().toggleFavorite();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(added ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieDetailViewModel>(
      builder: (context, viewModel, child) {
        final movie = viewModel.movie;

        return Scaffold(
          appBar: CommonAppBar(
            title: '영화 상세',
            onBack: () => context.pop(),
            actions: [
              if (movie != null)
                IconButton(
                  tooltip: viewModel.isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
                  icon: Icon(
                    viewModel.isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                  onPressed: () => _toggleFavorite(context),
                ),
            ],
          ),
          body: switch (viewModel.status) {
            LoadStatus.idle || LoadStatus.loading => const LoadingView(),
            LoadStatus.error => ErrorView(
              message: viewModel.message,
              onRetry: () => context.read<MovieDetailViewModel>().load(),
            ),
            LoadStatus.empty => const EmptyView(message: '영화 정보를 찾을 수 없어요.'),
            LoadStatus.success => _DetailContent(movie: movie!),
          },
        );
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _DetailHeader(movie: movie),
        const SizedBox(height: 20),
        _AverageRating(movie: movie),
        const SizedBox(height: 20),
        const Text('줄거리', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        movie.overview.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('줄거리 정보가 없어요.', style: AppTextStyles.bodyMedium),
                ),
              )
            : Text(movie.overview, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        const _MyRatingSection(),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseYear;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TmdbPosterImage(posterPath: movie.posterPath, width: 120, height: 180),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(movie.title, style: AppTextStyles.titleLarge),
              if (year != null) ...[
                const SizedBox(height: 4),
                Text('$year년 개봉', style: AppTextStyles.bodyMedium),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final name in movie.genreNames)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// TMDB 평균 평점을 RatingBarIndicator로 읽기 전용 표시합니다.
class _AverageRating extends StatelessWidget {
  const _AverageRating({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('평균 평점', style: AppTextStyles.titleMedium),
          const Spacer(),
          MovieRatingIndicator(rating: movie.fiveStarAverage),
          const SizedBox(width: 8),
          Text(
            movie.fiveStarAverage.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 영화 상세 화면에서는 평점 "등록"만 합니다. 조회·수정·삭제는 마이페이지에서 진행합니다.
class _MyRatingSection extends StatelessWidget {
  const _MyRatingSection();

  Future<void> _openRatingDialog(BuildContext context) async {
    final viewModel = context.read<MovieDetailViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        movieTitle: viewModel.movie?.title,
        onSubmit: (score, comment) async {
          // movieId는 이 화면의 ViewModel이 이미 갖고 있으므로 따로 전달하지 않습니다.
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            throw StateError(viewModel.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );

    // 저장 요청과 Snackbar 표시는 다른 비동기 경계이므로 mounted를 다시 확인합니다.
    if (!context.mounted || saved != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '보기',
            onPressed: () => context.push('/my/ratings'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final hasMember = viewModel.memberId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MovieLogButton(
          label: '평점 남기기',
          width: double.infinity,
          height: 48,
          // 학습용 회원가입 결과(memberId)가 없으면 등록할 수 없습니다.
          onPressed: viewModel.canRate
              ? () => _openRatingDialog(context)
              : null,
        ),
        if (!hasMember) ...[
          const SizedBox(height: 8),
          const Text(
            '평점을 남기려면 먼저 학습용 회원가입을 완료해 주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('회원가입하러 가기'),
          ),
        ],
      ],
    );
  }
}
