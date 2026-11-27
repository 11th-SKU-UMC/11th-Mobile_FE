import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_spacing.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/movie_page_footer.dart';

/// 영화 검색(`/movies/search`). 영화 목록과 별도의 [PagedMoviesViewModel]을 쓴다.
///
/// - 검색어를 제출할 때(키보드 검색·검색 버튼)만 요청한다. 입력 중에는 요청하지 않는다.
/// - 빈 검색어는 서버에 보내지 않고 입력 안내를 보여준다.
/// - 처음 진입(idle)과 결과 없음(empty)을 구분한다.
/// - root Navigator 위에 열려 하단 NavigationBar가 없다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  static const String idleMessage = '찾고 싶은 영화 제목을 입력하고 검색해 보세요.';
  static const String emptyQueryMessage = '검색어를 입력해 주세요.';
  static const String noResultMessage = '검색 결과가 없습니다.';

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _text = TextEditingController();
  String? _inputError;

  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _inputError = MovieSearchScreen.emptyQueryMessage);
      return;
    }
    setState(() => _inputError = null);
    FocusScope.of(context).unfocus();
    // 새 검색은 항상 page 1부터. 이전 검색어의 늦은 응답은 ViewModel이 버린다.
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '영화 검색', centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                decoration: InputDecoration(
                  hintText: '영화 제목',
                  errorText: _inputError,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: '검색',
                    onPressed: () => _submitSearch(_text.text),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: Consumer<PagedMoviesViewModel>(
                builder: (context, vm, _) {
                  return switch (vm.phase) {
                    LoadPhase.idle => const MovieListEmpty(
                      message: MovieSearchScreen.idleMessage,
                    ),
                    LoadPhase.loading => const MovieListLoading(),
                    LoadPhase.error => MovieListError(
                      message:
                          vm.errorMessage ??
                          PagedMoviesViewModel.searchFailedMessage,
                      onRetry: vm.retryInitial,
                    ),
                    LoadPhase.empty => MovieListEmpty(
                      message:
                          '"${vm.query}"에 대한 ${MovieSearchScreen.noResultMessage}',
                    ),
                    LoadPhase.ready => CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: movieGridPadding,
                          sliver: SliverGrid.builder(
                            gridDelegate: movieGridDelegate,
                            itemCount: vm.movies.length,
                            itemBuilder: (context, index) {
                              final movie = vm.movies[index];
                              return MovieCard(
                                key: ValueKey(movie.id),
                                movie: movie,
                                onTap: () => widget.onOpenMovie(movie),
                              );
                            },
                          ),
                        ),
                        SliverToBoxAdapter(child: MoviePageFooter(vm: vm)),
                      ],
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
