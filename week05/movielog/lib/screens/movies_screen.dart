import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_list_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  MovieListViewModel? _viewModel;
  int _handledFailure = 0;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<MovieListViewModel>();
    if (identical(viewModel, _viewModel)) return;
    _viewModel?.removeListener(_onChanged);
    _viewModel = viewModel;
    _handledFailure = 0;
    viewModel.addListener(_onChanged);
  }

  void _onChanged() {
    final viewModel = _viewModel;
    if (viewModel == null ||
        !viewModel.showingPreviousResults ||
        viewModel.failureVersion <= _handledFailure ||
        _dialogOpen) {
      return;
    }
    _handledFailure = viewModel.failureVersion;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showFailure(viewModel),
    );
  }

  Future<void> _showFailure(MovieListViewModel viewModel) async {
    if (!mounted ||
        !identical(viewModel, _viewModel) ||
        !viewModel.showingPreviousResults ||
        _dialogOpen) {
      return;
    }
    _dialogOpen = true;
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영화를 불러오지 못했어요'),
        content: const Text('최근에 불러온 목록을 유지했어요. 같은 장르 조건으로 다시 시도할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('재시도'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (retry == true && mounted && identical(viewModel, _viewModel)) {
      await viewModel.retry();
    }
  }

  Future<void> _selectMultipleGenres(MovieListViewModel viewModel) async {
    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GenreFilterSheet(
        genres: viewModel.genres,
        initialGenreIds: viewModel.selectedGenreIds,
      ),
    );
    if (!mounted || selected == null || !identical(viewModel, _viewModel)) {
      return;
    }
    await viewModel.selectGenres(selected);
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '영화'),
      body: SafeArea(
        child: Consumer<MovieListViewModel>(
          builder: (context, viewModel, child) => Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('전체'),
                        selected: viewModel.selectedGenreIds == null,
                        onSelected: viewModel.isLoading
                            ? null
                            : (_) => viewModel.selectGenres(null),
                      ),
                    ),
                    for (final genre in viewModel.genres)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(genre.name),
                          selected:
                              viewModel.selectedGenreIds?.contains(genre.id) ??
                              false,
                          onSelected: viewModel.isLoading
                              ? null
                              : (selected) => viewModel.selectGenres(
                                  selected ? [genre.id] : null,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text('영화 ${viewModel.movies.length}편')),
                    TextButton.icon(
                      onPressed: viewModel.isLoading || viewModel.genres.isEmpty
                          ? null
                          : () => _selectMultipleGenres(viewModel),
                      icon: const Icon(Icons.tune),
                      label: const Text('장르 선택'),
                    ),
                  ],
                ),
              ),
              if (viewModel.isLoading && viewModel.showMovies)
                const LinearProgressIndicator(),
              if (viewModel.showingPreviousResults)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('이전 조회 결과입니다. 선택한 조건으로 다시 시도해 주세요.'),
                      ),
                      TextButton(
                        onPressed: viewModel.retry,
                        child: const Text('재시도'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  notificationPredicate: (notification) =>
                      !viewModel.isLoading && notification.depth == 0,
                  onRefresh: viewModel.refresh,
                  child: _buildMovies(viewModel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovies(MovieListViewModel viewModel) {
    if (viewModel.showMovies) {
      return MovieGrid(movies: viewModel.movies, genres: viewModel.genres);
    }
    return switch (viewModel.status) {
      MovieListLoadStatus.idle ||
      MovieListLoadStatus.loading => const MovieListLoading(),
      MovieListLoadStatus.error => MovieListError(
        message: viewModel.message ?? '영화를 불러오지 못했어요.',
        onRetry: viewModel.retry,
      ),
      MovieListLoadStatus.empty => LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: const MovieListEmpty(),
            ),
          ],
        ),
      ),
      MovieListLoadStatus.success => MovieGrid(
        movies: viewModel.movies,
        genres: viewModel.genres,
      ),
    };
  }
}
