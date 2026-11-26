import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_list_view_model.dart';
import '../widgets/tmdb_movie_card.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/movies/search');
            },
            icon: const Icon(Icons.search),
            tooltip: '영화 검색',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GenreChips(viewModel: viewModel),
          Expanded(child: _MovieListBody(viewModel: viewModel)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/movies');
            case 2:
              context.go('/my');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: '영화',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.viewModel});

  final MovieListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('전체'),
              selected: viewModel.selectedGenreId == null,
              onSelected: viewModel.isLoading
                  ? null
                  : (_) {
                      viewModel.selectGenre(null);
                    },
            ),
          ),
          ...viewModel.genres.map(
            (genre) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(genre.name),
                selected: viewModel.selectedGenreId == genre.id,
                onSelected: viewModel.isLoading
                    ? null
                    : (_) {
                        viewModel.selectGenre(genre.id);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieListBody extends StatelessWidget {
  const _MovieListBody({required this.viewModel});

  final MovieListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.retry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (viewModel.movies.isEmpty) {
      return const Center(child: Text('영화가 없습니다.'));
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.movies.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final movie =
                  viewModel.movies[index];

              return TmdbMovieCard(
                movie: movie,
                onTap: () {
                  context.push(
                    '/movies/${movie.id}',
                    extra: movie,
                  );
                },
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child: Column(
            children: [
              if (viewModel.loadMoreErrorMessage != null) ...[
                Text(
                  viewModel.loadMoreErrorMessage!,
                ),
                const SizedBox(height: 8),
              ],

              SizedBox(
                width: double.infinity,
                child: viewModel.isLoadingMore
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : FilledButton.icon(
                        onPressed: viewModel.canLoadMore
                            ? viewModel.loadMore
                            : null,
                        icon: const Icon(
                          Icons.expand_more,
                        ),
                        label: Text(
                          viewModel.loadMoreErrorMessage != null
                              ? '다시 시도'
                              : viewModel.canLoadMore
                                  ? '더 보기'
                                  : '마지막 페이지입니다.',
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
