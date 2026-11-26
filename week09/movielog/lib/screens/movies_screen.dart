import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/paged_movies_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/paged_movie_results.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNearEnd);
  }

  void _loadNearEnd() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions ||
        _scrollController.position.extentAfter > 300) {
      return;
    }
    final viewModel = context.read<PagedMoviesViewModel>();
    if (viewModel.loadMoreError == null) viewModel.loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadNearEnd);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectMultipleGenres(PagedMoviesViewModel viewModel) async {
    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GenreFilterSheet(
        genres: viewModel.genres,
        initialGenreIds: viewModel.genreIds,
      ),
    );
    if (mounted && selected != null) await viewModel.selectGenres(selected);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '영화 검색',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/movies/search'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('전체'),
                    selected: viewModel.genreIds.isEmpty,
                    onSelected: (_) => viewModel.selectGenres(const []),
                  ),
                  for (final genre in viewModel.genres)
                    ChoiceChip(
                      label: Text(genre.name),
                      selected: viewModel.genreIds.contains(genre.id),
                      onSelected: (selected) => viewModel.selectGenres(
                        selected ? [genre.id] : const [],
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
                    onPressed: viewModel.genres.isEmpty
                        ? null
                        : () => _selectMultipleGenres(viewModel),
                    icon: const Icon(Icons.tune),
                    label: const Text('장르 선택'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<OverscrollNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0 && notification.overscroll > 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _loadNearEnd();
                    });
                  }
                  return false;
                },
                child: PagedMovieResults(
                  viewModel: viewModel,
                  controller: _scrollController,
                  autoLoad: true,
                  idleMessage: '',
                  emptyMessage: '조건에 맞는 영화가 없습니다.',
                  errorMessage: '영화를 불러오지 못했습니다.',
                  onRefresh: () => Future.wait([
                    viewModel.loadInitial(),
                    viewModel.loadGenres(),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
