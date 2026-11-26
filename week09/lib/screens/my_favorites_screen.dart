import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/my_favorites_view_model.dart';
import '../widgets/tmdb_poster_image.dart';

class MyFavoritesScreen extends StatelessWidget {
  const MyFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel =
        context.watch<MyFavoritesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 즐겨찾기'),
      ),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading &&
              viewModel.movies.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.errorMessage != null &&
              viewModel.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(viewModel.errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: viewModel.loadFavorites,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.movies.isEmpty) {
            return const Center(
              child: Text(
                '즐겨찾기한 영화가 없습니다.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.movies.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final movie =
                    viewModel.movies[index];

                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 56,
                      height: 84,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: TmdbPosterImage(
                          posterPath:
                              movie.posterPath,
                        ),
                      ),
                    ),
                    title: Text(movie.title),
                    subtitle: Text(
                      movie.releaseDate?.isNotEmpty ==
                              true
                          ? movie.releaseDate!
                          : '개봉일 정보 없음',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      context.push(
                        '/movies/${movie.id}',
                        extra: movie,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}