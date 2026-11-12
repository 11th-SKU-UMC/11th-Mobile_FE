import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/movie.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_detail_sections.dart';
import '../widgets/rating_dialog.dart';

/// 영화 상세 화면. `/movies/:movieId`의 Path Parameter로 받은 ID로 Mock 데이터를 다시 찾는다.
///
/// Extra로 Movie 객체를 넘기지 않는 이유: URL을 직접 열거나 앱을 다시 시작하면
/// Extra는 비어 있지만 ID는 URL에 항상 남아 있기 때문.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final int? movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 즐겨찾기와 내 평점은 서버 없이 이 화면 안의 상태로만 관리한다. (API 연결은 8주차)
  bool _isFavorite = false;
  double? _myRating;

  Movie? get _movie => findMovieById(widget.movieId);

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

  Future<void> _openRatingDialog(Movie movie) async {
    final rating = await RatingDialog.show(
      context,
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

  Widget _buildBody(Movie movie) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset(movie.headerImage, fit: BoxFit.cover),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MovieInfoSection(movie: movie, myRating: _myRating),
        ),
        Divider(color: colors.outlineVariant, height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SynopsisSection(synopsis: movie.synopsis),
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
