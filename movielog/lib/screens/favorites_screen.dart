import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/widgets/movie_row_card.dart';
import 'package:movielog/widgets/movielog_button.dart';

// 내 즐겨찾기 (/my/favorites) — 하단 NavigationBar 없음, 가운데 제목 + 뒤로가기
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // build()에서는 조회하지 않습니다. 첫 프레임 뒤에 한 번만 호출합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  String? _year(TmdbMovieDto movie) {
    final date = movie.releaseDate;
    return (date != null && date.length >= 4) ? date.substring(0, 4) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 즐겨찾기', style: AppTextStyles.titleAppBar),
        centerTitle: true,
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) {
          switch (vm.phase) {
            case LoadPhase.idle:
            case LoadPhase.loading:
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            case LoadPhase.empty:
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 36,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '아직 즐겨찾기한 영화가 없습니다.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '영화 상세에서 북마크를 눌러보세요.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            case LoadPhase.error:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.errorMessage ?? '즐겨찾기를 불러오지 못했습니다.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MovieLogButton(
                      label: '다시 시도',
                      width: 220,
                      onPressed: vm.refresh,
                    ),
                  ],
                ),
              );
            case LoadPhase.ready:
              return RefreshIndicator(
                onRefresh: vm.refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: vm.items.length,
                  itemBuilder: (context, index) {
                    final item = vm.items[index];
                    final movie = item.movie;

                    // 영화 정보 한 건만 실패: placeholder + 재조회 (다른 카드는 그대로)
                    if (movie == null) {
                      return MovieRowCard(
                        title: '영화 #${item.favorite.movieId}',
                        posterPath: null,
                        showPoster: false,
                        subtitle: item.errorMessage ?? '정보가 없습니다.',
                        tag: '즐겨찾기한 영화',
                        action: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: vm.refresh,
                          child: const Text(
                            '정보 다시 불러오기',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    return MovieRowCard(
                      title: movie.title,
                      posterPath: movie.posterPath,
                      subtitle: _year(movie),
                      tag: '즐겨찾기한 영화',
                      onTap: () async {
                        await widget.onOpenMovie(movie);
                        if (!mounted) return;
                        // 상세에서 해제하고 돌아오면 목록을 다시 조회합니다.
                        await vm.refresh();
                      },
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
