import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_detail_sections.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면. `/movies/:movieId`의 [movieId]는 TMDB 영화 id다.
///
/// 화면에 그릴 정보는 홈·목록에서 extra로 넘긴 [movie]를 쓴다.
/// URL을 직접 열어 extra가 비어 있으면 '찾을 수 없음'을 보여준다.
/// (TMDB 상세 API로 id만으로 다시 불러오는 것은 이번 주 범위가 아니다.)
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  final int? movieId;
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 즐겨찾기와 내 평점은 서버 없이 이 화면 안의 상태로만 관리한다. (API 연결은 8주차)
  bool _isFavorite = false;
  double? _myRating;

  /// extra와 URL의 id가 다르면 잘못 넘어온 값이라 쓰지 않는다.
  TmdbMovieDto? get _movie {
    final movie = widget.movie;
    if (movie == null || movie.id != widget.movieId) return null;
    return movie;
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

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showSnackBar(
      _isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.',
      icon: _isFavorite ? Icons.bookmark : Icons.bookmark_remove_outlined,
    );
  }

  Future<void> _openRatingDialog(TmdbMovieDto movie) async {
    final rating = await RatingDialog.show(
      context,
      // 배열 index가 아니라 TMDB id를 넘긴다. 이후 평점 API의 movieId가 된다.
      movieId: movie.id,
      movieTitle: movie.title,
      initialRating: _myRating ?? 0,
    );
    // 취소하거나 바깥을 눌러 닫으면 null이 온다.
    if (rating == null || !mounted) return;

    setState(() => _myRating = rating);
    _showSnackBar(
      '평점 ${rating.toStringAsFixed(1)}점을 남겼어요.',
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
    final movie = _movie;

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
          if (movie != null)
            IconButton(
              tooltip: '공유',
              onPressed: () => _showSnackBar(
                '공유 기능은 아직 준비 중이에요.',
                icon: Icons.share_outlined,
              ),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: movie == null ? const _MovieNotFound() : _buildBody(movie),
      bottomNavigationBar: movie == null
          ? null
          : DetailActionBar(
              isFavorite: _isFavorite,
              onFavoritePressed: _toggleFavorite,
              onRatePressed: () => _openRatingDialog(movie),
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
          child: MovieInfoSection(movie: movie, myRating: _myRating),
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

class _MovieNotFound extends StatelessWidget {
  const _MovieNotFound();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_outlined, size: 48, color: colors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              '영화를 찾을 수 없어요.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
