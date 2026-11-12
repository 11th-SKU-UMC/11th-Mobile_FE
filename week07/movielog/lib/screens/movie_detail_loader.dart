import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import 'movie_detail_screen.dart';

/// 영화 상세 화면의 시작점.
///
/// 홈·목록에서 넘긴 [initialMovie](extra)가 있으면 그대로 쓰고,
/// 직접 접근·Deep Link처럼 없으면 TMDB `GET /movie/{id}`로 다시 조회한다.
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  /// build마다 새 Future를 만들지 않도록 State에 보관한다.
  late Future<TmdbMovieDto?> _movieFuture = _load();

  Future<TmdbMovieDto?> _load() {
    final initial = widget.initialMovie;
    if (initial != null) return Future.value(initial);
    // 404(없는 영화)만 null, 다른 오류는 snapshot.error로 온다.
    return context.read<TmdbMovieService>().findMovieById(widget.movieId);
  }

  void _retry() => setState(() => _movieFuture = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto?>(
      future: _movieFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DetailMessageScaffold(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return _DetailMessageScaffold(
            message: '영화를 불러오지 못했습니다.',
            action: MovieLogButton(
              label: '다시 시도',
              width: 120,
              onPressed: _retry,
            ),
          );
        }
        final movie = snapshot.data;
        if (movie == null) {
          return const _DetailMessageScaffold(message: '영화를 찾을 수 없어요.');
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            context.read<LearningMemberSession>().memberId,
            movie,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}

/// URL의 movieId가 숫자가 아니거나 1보다 작을 때.
class InvalidMovieIdScreen extends StatelessWidget {
  const InvalidMovieIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailMessageScaffold(message: '영화 ID가 올바르지 않습니다.');
  }
}

class _DetailMessageScaffold extends StatelessWidget {
  const _DetailMessageScaffold({this.message, this.action, this.child});

  final String? message;
  final Widget? action;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = this.message;

    return Scaffold(
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?child,
              if (message != null) ...[
                Icon(
                  Icons.movie_filter_outlined,
                  size: 48,
                  color: colors.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.md),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
