import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/movie.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';
import '../widgets/tab_app_bar.dart';

/// 영화 목록 탭.
///
/// 선택한 장르는 화면 State가 아니라 URL의 Query Parameter로 들고 있다.
/// 예: `/movies?genre=드라마&genre=SF`
/// Router가 URL에서 읽어 [selectedGenres]로 넘겨주므로, 필터를 바꿀 때는 URL만 바꾸면 된다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final List<String> selectedGenres;

  void _applyGenres(BuildContext context, List<String> genres) {
    // go: 같은 탭 안에서 Query Parameter만 바꾼다. 필터 변경은 뒤로 가기 기록을 쌓지 않는다.
    context.go(AppRoutes.moviesWithGenres(genres));
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await GenreFilterSheet.show(
      context,
      genres: movieGenres,
      initialSelection: selectedGenres.toSet(),
    );
    // 바깥을 눌러 닫은 경우(null)에는 필터를 바꾸지 않는다.
    if (result == null || !context.mounted) return;

    _applyGenres(context, result);
    // BottomSheet가 닫힌 뒤에 Snackbar를 띄워야 Sheet 뒤에 가려지지 않는다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.isEmpty
                ? '전체 영화를 보여드려요.'
                : '${result.join(', ')} 장르만 보여드려요.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMovies = filterMoviesByGenres(selectedGenres);

    return Scaffold(
      appBar: TabAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '장르 필터',
            onPressed: () => _openFilterSheet(context),
            icon: Badge(
              isLabelVisible: selectedGenres.isNotEmpty,
              label: Text('${selectedGenres.length}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          GenreFilterChips(
            genres: movieGenres,
            selectedGenres: selectedGenres.toSet(),
            onSelected: (genres) => _applyGenres(context, genres),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: visibleMovies.isEmpty
                ? const _EmptyResult()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: visibleMovies.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md - 4,
                          mainAxisSpacing: AppSpacing.lg,
                          childAspectRatio: 0.56,
                        ),
                    itemBuilder: (context, index) {
                      final movie = visibleMovies[index];
                      return MovieCard(
                        movie: movie,
                        // push: 목록을 Stack에 남겨서 상세에서 뒤로 가면 같은 필터의 목록으로 돌아온다.
                        onTap: () =>
                            context.push(AppRoutes.movieDetail(movie.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        '선택한 장르의 영화가 없어요.',
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}
