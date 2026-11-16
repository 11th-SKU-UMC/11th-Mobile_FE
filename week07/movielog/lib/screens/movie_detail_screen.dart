import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_detail_sections.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면. 영화 정보와 평점 등록 상태는 [MovieDetailViewModel]에서 읽는다.
///
/// 평점은 등록만 하고, 결과는 같은 화면의 Snackbar로 안내한다.
/// 학습용 memberId가 없으면 등록 버튼을 막고 회원가입으로 안내한다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  static const String ratingSavedMessage =
      '평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.';
  static const String signUpGuideMessage = '평점을 남기려면 학습용 회원가입이 필요합니다.';

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 즐겨찾기는 서버 없이 이 화면 안의 상태로만 관리한다. (API 연결은 8주차)
  bool _isFavorite = false;

  void _goBack() {
    // 홈·목록에서 push로 들어왔으면 pop으로 돌아간다.
    // URL로 바로 열려서 돌아갈 화면이 없으면 홈으로 보낸다.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showSnackBar(
      _isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.',
      icon: _isFavorite ? Icons.bookmark : Icons.bookmark_remove_outlined,
    );
  }

  Future<void> _openRatingDialog() async {
    // Dialog는 root Navigator에 뜨므로 이 화면의 ViewModel을 미리 꺼내 둔다.
    final viewModel = context.read<MovieDetailViewModel>();
    final saved = await RatingDialog.show(
      context,
      movieTitle: viewModel.movie.title,
      onSubmit: (score, comment) async {
        await viewModel.createRating(score: score, comment: comment);
        // 실패하면 throw해야 Dialog가 닫히지 않고 오류를 보여준다.
        if (viewModel.submitStatus != SubmitStatus.success) {
          throw StateError(
            viewModel.submitMessage ?? RatingDialog.defaultErrorMessage,
          );
        }
      },
    );
    // 저장 요청과 Snackbar 표시 사이에 화면이 사라졌을 수 있다.
    if (!mounted || saved != true) return;

    _showSnackBar(
      MovieDetailScreen.ratingSavedMessage,
      icon: Icons.star_rounded,
    );
  }

  void _showSnackBar(String message, {required IconData icon}) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: colors.onInverseSurface, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<MovieDetailViewModel>();

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        centerTitle: true,
        titleStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: '공유',
            onPressed: () =>
                _showSnackBar('공유 기능은 아직 준비 중이에요.', icon: Icons.share_outlined),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: _buildBody(viewModel.movie),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!viewModel.canRate) const _SignUpGuide(),
          DetailActionBar(
            isFavorite: _isFavorite,
            onFavoritePressed: _toggleFavorite,
            // memberId가 없으면 다른 회원의 path로 요청하지 않도록 버튼을 막는다.
            onRatePressed: viewModel.canRate ? _openRatingDialog : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TmdbMovieDto movie) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          // 가로 이미지(backdrop)가 없으면 포스터를 대신 쓴다.
          child: TmdbPosterImage(
            posterPath: movie.backdropPath ?? movie.posterPath,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MovieInfoSection(movie: movie),
        ),
        Divider(color: colors.outlineVariant, height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SynopsisSection(synopsis: movie.overview),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// 학습용 memberId가 없을 때 하단 버튼 위에 보여주는 회원가입 안내.
class _SignUpGuide extends StatelessWidget {
  const _SignUpGuide();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                MovieDetailScreen.signUpGuideMessage,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
