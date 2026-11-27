import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_spacing.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/movielog_button.dart';

/// 마이페이지 → 내 즐겨찾기.
///
/// root Navigator 위에 열려 하단 NavigationBar가 없고, 앱바 가운데 제목과 뒤로 가기가 있다.
/// 목록·빈 목록·조회 오류·영화 정보 한 건 실패를 각각 다르게 그린다.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  static const String emptyMessage = '아직 즐겨찾기한 영화가 없어요.\n영화 상세에서 북마크를 눌러 보세요.';

  /// 상세로 이동하고, 상세에서 돌아오면 완료되는 Future를 돌려준다.
  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  Future<void> _open(TmdbMovieDto movie) async {
    final viewModel = context.read<FavoritesViewModel>();
    await widget.onOpenMovie(movie);
    if (!mounted) return;
    // 상세에서 해제했을 수 있으니 돌아오면 다시 조회한다. (세션 확인은 ViewModel이 한다)
    await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 즐겨찾기', centerTitle: true),
      body: SafeArea(
        child: Consumer<FavoritesViewModel>(
          builder: (context, vm, _) {
            return switch (vm.phase) {
              LoadPhase.idle || LoadPhase.loading => const MovieListLoading(),
              LoadPhase.error => MovieListError(
                message:
                    vm.errorMessage ?? FavoritesViewModel.listFailedMessage,
                onRetry: vm.refresh,
              ),
              LoadPhase.empty => RefreshIndicator(
                onRefresh: vm.refresh,
                child: const MovieListEmpty(
                  message: FavoritesScreen.emptyMessage,
                ),
              ),
              LoadPhase.ready => RefreshIndicator(
                onRefresh: vm.refresh,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: movieGridPadding,
                  gridDelegate: movieGridDelegate,
                  itemCount: vm.items.length,
                  itemBuilder: (context, index) {
                    final item = vm.items[index];
                    final movie = item.movie;
                    if (movie == null) {
                      return _MovieInfoFailedCard(
                        key: ValueKey('failed-${item.favorite.movieId}'),
                        item: item,
                        isRetrying: vm.retryingMovieIds.contains(
                          item.favorite.movieId,
                        ),
                        onRetry: () => vm.retryMovie(item.favorite.movieId),
                      );
                    }
                    return MovieCard(
                      key: ValueKey(movie.id),
                      movie: movie,
                      onTap: () => _open(movie),
                    );
                  },
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

/// TMDB 영화 정보를 가져오지 못한 즐겨찾기 카드. 다른 카드는 그대로 두고 이 카드만 재조회한다.
class _MovieInfoFailedCard extends StatelessWidget {
  const _MovieInfoFailedCard({
    super.key,
    required this.item,
    required this.isRetrying,
    required this.onRetry,
  });

  final FavoriteListItem item;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: colors.outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.errorMessage ?? FavoritesViewModel.movieFailedMessage,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                MovieLogButton(
                  label: '정보 재조회',
                  height: 36,
                  isLoading: isRetrying,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '영화 #${item.favorite.movieId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
