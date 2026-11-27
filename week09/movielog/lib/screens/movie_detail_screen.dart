import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/favorite_button.dart';
import '../widgets/movie_detail_sections.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면. 영화 정보와 평점 등록 상태는 [MovieDetailViewModel]에서,
/// 즐겨찾기 상태는 Route가 제공한 [FavoriteDetailViewModel]에서 읽는다.
///
/// 평점은 등록만 하고, 결과는 같은 화면의 Snackbar로 안내한다.
/// 이 화면은 로그인된 상태에서만 열린다(Router redirect). 사용자는 토큰으로 식별한다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  static const String ratingSavedMessage =
      '평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.';

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 서버의 즐겨찾기 여부는 화면이 처음 만들어질 때 한 번만 조회한다. (build에서 조회하지 않음)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteDetailViewModel>().load();
    });
  }

  void _goBack() {
    // 홈·목록에서 push로 들어왔으면 pop으로 돌아간다.
    // URL로 바로 열려서 돌아갈 화면이 없으면 홈으로 보낸다.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _openRatingDialog() async {
    // Dialog는 root Navigator에 뜨므로 이 화면의 ViewModel을 미리 꺼내 둔다.
    final viewModel = context.read<MovieDetailViewModel>();
    final saved = await RatingDialog.show(
      context,
      movieTitle: viewModel.movie.title,
      // 실패하면 ViewModel이 throw한다. 입력 오류는 Dialog 안에, 409 등은 Dialog를 닫고
      // 아래에서 Snackbar로 안내한다. 세션 만료는 로그인 화면이 안내한다.
      onSubmit: (score, comment) =>
          viewModel.createRating(score: score, comment: comment),
    );
    // 저장 요청과 Snackbar 표시 사이에 화면이 사라졌을 수 있다.
    if (!mounted) return;
    if (saved != true) {
      final message = viewModel.takeSnackbarMessage();
      if (message != null) _showSnackBar(message, icon: Icons.info_outline);
      return;
    }

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
      bottomNavigationBar: DetailActionBar(onRatePressed: _openRatingDialog),
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
          // 제목·정보 오른쪽에 서버와 연결된 북마크 버튼을 둔다.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: MovieInfoSection(movie: movie)),
              const SizedBox(width: AppSpacing.sm),
              const FavoriteButton(),
            ],
          ),
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
