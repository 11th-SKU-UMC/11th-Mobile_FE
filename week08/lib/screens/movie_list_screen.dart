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
      appBar: AppBar(title: const Text('영화')),
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final movie = viewModel.movies[index];

        return TmdbMovieCard(
          movie: movie,
          onTap: () {
            context.push('/movies/${movie.id}', extra: movie);
          },
        );
      },
    );
  }
}
