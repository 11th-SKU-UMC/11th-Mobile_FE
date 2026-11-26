import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/async_state_views.dart';
import '../widgets/movie_card.dart';

/// 마이페이지 → 내 즐겨찾기(`/my/favorites`) 화면입니다.
///
/// 목록 전체 실패(오류 화면)와 영화 한 건의 정보 실패(그 카드만 placeholder)를 구분합니다.
/// 카드를 눌러 상세에서 즐겨찾기를 해제하고 돌아오면 목록을 다시 조회합니다.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  /// 상세 화면으로 이동하고, 돌아올 때까지 기다리는 함수입니다.
  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // build()에서는 조회하지 않고 화면이 처음 만들어질 때 한 번 조회합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  Future<void> _open(FavoritesViewModel vm, TmdbMovieDto movie) async {
    await widget.onOpenMovie(movie);
    if (!mounted) return;
    // 상세에서 해제했을 수 있으므로 서버 목록으로 다시 맞춥니다.
    await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('내 즐겨찾기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로 가기',
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) => switch (vm.phase) {
          LoadPhase.idle || LoadPhase.loading => const LoadingView(),
          LoadPhase.error => ErrorView(
            message: vm.errorMessage ?? '내 즐겨찾기 목록을 불러오지 못했습니다.',
            onRetry: vm.refresh,
          ),
          LoadPhase.empty => RefreshIndicator(
            onRefresh: vm.refresh,
            child: const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: EmptyView(
                    message: '아직 즐겨찾기한 영화가 없습니다.\n영화 상세에서 북마크를 눌러 추가해 보세요.',
                    icon: Icons.bookmark_border,
                  ),
                ),
              ],
            ),
          ),
          LoadPhase.ready => _FavoriteGrid(
            vm: vm,
            onOpen: (movie) => _open(vm, movie),
          ),
        },
      ),
    );
  }
}

class _FavoriteGrid extends StatelessWidget {
  const _FavoriteGrid({required this.vm, required this.onOpen});

  final FavoritesViewModel vm;
  final void Function(TmdbMovieDto movie) onOpen;

  @override
  Widget build(BuildContext context) {
    final refreshError = vm.refreshError;
    return Column(
      children: [
        if (vm.isRefreshing) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  refreshError ?? '즐겨찾기 ${vm.items.length}편',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: refreshError == null ? null : AppColors.error,
                  ),
                ),
              ),
              if (refreshError != null)
                TextButton(onPressed: vm.refresh, child: const Text('다시 시도')),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: vm.refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: vm.items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  final movie = item.movie;
                  if (movie == null) {
                    return _MissingMovieCard(
                      item: item,
                      onRetry: () => vm.retryMovie(item.favorite.favoriteId),
                    );
                  }
                  // 기존 영화 카드를 재사용하고, 이동만 직접 처리해 돌아온 뒤 목록을 갱신합니다.
                  return MovieCard(
                    key: ValueKey(item.favorite.favoriteId),
                    movie: movie,
                    onTap: () => onOpen(movie),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// TMDB 정보를 가져오지 못한 카드입니다. 다른 카드는 그대로 두고 이 카드만 다시 조회합니다.
class _MissingMovieCard extends StatelessWidget {
  const _MissingMovieCard({required this.item, required this.onRetry});

  final FavoriteListItem item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_outlined, color: AppColors.gray),
                const SizedBox(height: 8),
                Text(
                  item.errorMessage ?? '영화 정보가 없습니다.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                item.isRetrying
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: onRetry,
                        child: const Text('정보 재조회'),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '영화 #${item.favorite.movieId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
