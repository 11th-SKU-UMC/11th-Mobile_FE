import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movielog_button.dart';

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
    // build()에서 조회하지 않고, 첫 프레임 뒤에 한 번만 조회합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('내 즐겨찾기'), centerTitle: true),
        body: Consumer<FavoritesViewModel>(
          builder: (context, vm, _) {
            if (vm.phase == LoadPhase.idle || vm.phase == LoadPhase.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.phase == LoadPhase.empty) {
              return const Center(child: Text('아직 즐겨찾기한 영화가 없습니다.'));
            }

            if (vm.phase == LoadPhase.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.errorMessage ?? '조회 오류입니다.'),
                    MovieLogButton(label: '다시 시도', onPressed: vm.refresh),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: vm.items.length,
                itemBuilder: (context, index) {
                  final item = vm.items[index], movie = item.movie;

                  // 영화 정보 한 건만 실패: placeholder + 재조회 버튼
                  if (movie == null) {
                    return ListTile(
                      leading: const Icon(Icons.broken_image_outlined),
                      title: Text('영화 #${item.favorite.movieId}'),
                      subtitle: Text(item.errorMessage ?? '정보가 없습니다.'),
                      trailing: MovieLogButton(
                        width: 110,
                        label: '정보 재조회',
                        onPressed: vm.refresh,
                      ),
                    );
                  }

                  final path = movie.posterPath;

                  return ListTile(
                    leading: path == null
                        ? const Icon(Icons.movie_outlined)
                        : Image.network(
                            'https://image.tmdb.org/t/p/w185$path',
                            width: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                    title: Text(movie.title),
                    trailing: const Icon(Icons.chevron_right),
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
          },
        ),
      );
}
