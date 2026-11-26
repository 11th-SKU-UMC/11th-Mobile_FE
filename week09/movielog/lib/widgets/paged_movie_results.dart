import 'package:flutter/material.dart';

import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movie_card.dart';
import 'movie_list_error.dart';
import 'movie_list_loading.dart';
import 'movie_page_footer.dart';

class PagedMovieResults extends StatelessWidget {
  const PagedMovieResults({
    super.key,
    required this.viewModel,
    required this.idleMessage,
    required this.emptyMessage,
    required this.errorMessage,
    this.autoLoad = false,
    this.controller,
    this.onRefresh,
  });

  final PagedMoviesViewModel viewModel;
  final String idleMessage;
  final String emptyMessage;
  final String errorMessage;
  final bool autoLoad;
  final ScrollController? controller;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final results = switch (viewModel.phase) {
      LoadPhase.idle => Center(child: Text(idleMessage)),
      LoadPhase.loading => const MovieListLoading(),
      LoadPhase.error => MovieListError(
        message: errorMessage,
        onRetry: onRefresh ?? viewModel.loadInitial,
      ),
      LoadPhase.empty => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(emptyMessage)),
          ),
        ],
      ),
      LoadPhase.ready => CustomScrollView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            sliver: SliverGrid.builder(
              itemCount: viewModel.movies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) => MovieCard(
                movie: viewModel.movies[index],
                genres: viewModel.genres,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: MoviePageFooter(viewModel, autoLoad: autoLoad),
          ),
        ],
      ),
    };
    final refresh = onRefresh;
    return refresh == null
        ? results
        : RefreshIndicator(onRefresh: refresh, child: results);
  }
}
