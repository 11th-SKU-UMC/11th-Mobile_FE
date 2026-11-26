import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/load_status.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/favorite_button.dart';
import '../widgets/movie_rating_input.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면입니다. 영화 정보·평점 등록은 [MovieDetailViewModel],
/// 즐겨찾기(북마크)는 [FavoriteDetailViewModel]이 담당합니다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 만들어질 때 서버의 즐겨찾기 여부를 한 번 조회합니다. build()에서는 조회하지 않습니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteDetailViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieDetailViewModel>(
      builder: (context, viewModel, child) {
        final movie = viewModel.movie;

        return Scaffold(
          appBar: CommonAppBar(title: '영화 상세', onBack: () => context.pop()),
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
        // 제목·정보 텍스트 오른쪽의 북마크입니다. 서버 결과로만 아이콘이 바뀝니다.
        const FavoriteButton(),
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
    final favorite = context.read<FavoriteDetailViewModel>();
    // Challenge: 아직 즐겨찾기하지 않은 영화로 확인된 경우에만 체크박스를 보여 주고
    // POST /v8/movie-records로 한 번에 저장합니다. 이미 즐겨찾기했거나 여부를 모르면 평점만 저장합니다.
    final useMovieRecord =
        viewModel.recordService != null &&
        favorite.hasLoadedStatus &&
        !favorite.isFavorite &&
        !favorite.isBusy;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        movieTitle: viewModel.movie?.title,
        showAddToFavorite: useMovieRecord,
        onSubmit: (score, comment, addToFavorites) async {
          // movieId는 이 화면의 ViewModel이 이미 갖고 있으므로 따로 전달하지 않습니다.
          await viewModel.createRating(
            score: score,
            comment: comment,
            addToFavorites: useMovieRecord ? addToFavorites : null,
          );
          if (viewModel.submitStatus == SubmitStatus.success) return;
          // 409·MEMBER404_1: Dialog를 닫고 Snackbar로 안내합니다.
          if (viewModel.shouldCloseDialog) throw const RatingDialogClose();
          // COMMON400·네트워크 실패: Dialog를 열어 둔 채 입력값을 유지합니다.
          throw StateError(viewModel.submitMessage ?? '저장에 실패했습니다.');
        },
      ),
    );

    // 저장 요청과 Snackbar 표시는 다른 비동기 경계이므로 mounted를 다시 확인합니다.
    if (!context.mounted) return;
    // 영화 기록 저장 뒤에는 북마크를 서버 값으로 다시 맞춥니다.
    if (viewModel.needsFavoriteSync) favorite.load();

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('평점을 저장했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '보기',
            onPressed: () => context.push('/my/ratings'),
          ),
        ),
      );
    } else if (viewModel.shouldCloseDialog &&
        viewModel.submitStatus == SubmitStatus.error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.submitMessage ?? '저장에 실패했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movieId = viewModel.movie?.id;
    // 이번 로그인에서 이미 이 영화에 남긴 평점이 있으면 함께 보여줍니다.
    final existing = movieId == null
        ? null
        : context.select<MyRatingsViewModel, RatingDto?>(
            (store) => store.findByMovieId(movieId)?.rating,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (existing != null) ...[
          Row(
            children: [
              const Text('내 평점', style: AppTextStyles.titleMedium),
              const Spacer(),
              MovieRatingIndicator(rating: existing.score.toDouble()),
              const SizedBox(width: 8),
              Text('${existing.score}점', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          MovieLogButton(
            label: '내 평점 관리하기',
            width: double.infinity,
            height: 48,
            onPressed: () => context.push('/my/ratings'),
          ),
        ] else
          MovieLogButton(
            label: '평점 남기기',
            width: double.infinity,
            height: 48,
            onPressed: viewModel.canRate
                ? () => _openRatingDialog(context)
                : null,
          ),
      ],
    );
  }
}
