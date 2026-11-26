import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_search_view_model.dart';
import '../widgets/tmdb_movie_card.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() =>
      _MovieSearchScreenState();
}

class _MovieSearchScreenState
    extends State<MovieSearchScreen> {
  final TextEditingController _controller =
      TextEditingController();

  String? _inputError;

  void _submit() {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      setState(() {
        _inputError = '검색어를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _inputError = null;
    });

    context
        .read<MovieSearchViewModel>()
        .search(query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
        context.watch<MovieSearchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction:
                  TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: '검색어',
                hintText: '영화 제목을 입력하세요.',
                errorText: _inputError,
                suffixIcon: IconButton(
                  onPressed: _submit,
                  icon:
                      const Icon(Icons.search),
                ),
                border:
                    const OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: _SearchBody(
              viewModel: viewModel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.viewModel,
  });

  final MovieSearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasSearched) {
      return const Center(
        child: Text(
          '검색어를 입력해주세요.',
        ),
      );
    }

    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.movies.isEmpty) {
      return Center(
        child: Text(
          viewModel.errorMessage!,
        ),
      );
    }

    if (viewModel.movies.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount:
                viewModel.movies.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder:
                (context, index) {
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

        if (viewModel.canLoadMore ||
            viewModel.isLoadingMore)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            child: SizedBox(
              width: double.infinity,
              child:
                  viewModel.isLoadingMore
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : FilledButton.icon(
                          onPressed:
                              viewModel
                                  .loadMore,
                          icon: const Icon(
                            Icons.expand_more,
                          ),
                          label:
                              const Text(
                            '더 보기',
                          ),
                        ),
            ),
          ),
      ],
    );
  }
}