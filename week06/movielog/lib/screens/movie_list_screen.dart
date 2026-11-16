import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

/// 영화 목록 화면.
/// 상태(로딩/성공/빈 목록/오류)는 MovieListViewModel이 들고 있고,
/// 이 화면은 그 상태를 Consumer로 구독해 표시만 한다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final MovieListViewModel _vm;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<MovieListViewModel>();
    _vm.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelChanged);
    super.dispose();
  }

  /// ViewModel이 "요청 실패 안내"를 요청하면 재시도 Dialog를 한 번만 띄운다.
  void _onViewModelChanged() {
    if (!_vm.hasRetryPrompt || _dialogShowing || !mounted) return;
    _dialogShowing = true;

    // notifyListeners는 build 도중에도 호출될 수 있어 프레임이 끝난 뒤에 Dialog를 연다.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _dialogShowing = false;
        return;
      }
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('영화를 불러오지 못했어요'),
          content: Text(_vm.retryMessage ?? '잠시 후 다시 시도해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
      _dialogShowing = false;
      if (!mounted) return;

      if (retry == true) {
        _vm.retry();
      } else {
        _vm.cancelRetry();
      }
    });
  }

  Future<void> _openFilterSheet() async {
    final vm = context.read<MovieListViewModel>();
    if (vm.isBusy) return;

    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GenreFilterSheet(
        genres: vm.genres,
        initialSelected: vm.selectedGenreIds.toSet(),
      ),
    );

    if (result == null || !mounted) return;
    vm.applyGenres(result.toList());
  }

  /// 영화의 genre_ids 중 Genre API 목록에서 처음 찾은 장르 이름.
  String? _genreName(List<TmdbGenreDto> genres, TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      for (final genre in genres) {
        if (genre.id == id) return genre.name;
      }
    }
    return null;
  }

  /// 선택된 장르 요약 문구 ("전체" 또는 "액션, 모험")
  String _selectedSummary(MovieListViewModel vm) {
    if (vm.selectedGenreIds.isEmpty) return '전체';
    final names = <String>[];
    for (final id in vm.selectedGenreIds) {
      for (final genre in vm.genres) {
        if (genre.id == id) names.add(genre.name);
      }
    }
    return names.isEmpty ? '전체' : names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '영화',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.violet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search, color: AppColors.black),
                  ),
                ],
              ),
              // 선택된 장르 요약 + 장르 필터 버튼 (요청 중에는 비활성화)
              Consumer<MovieListViewModel>(
                builder: (context, vm, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedSummary(vm),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: vm.isBusy ? null : _openFilterSheet,
                        icon: Icon(
                          Icons.filter_list,
                          color: vm.isBusy ? AppColors.gray : AppColors.violet,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<MovieListViewModel>(
                  builder: (context, vm, child) {
                    return switch (vm.status) {
                      MovieListLoadStatus.idle ||
                      MovieListLoadStatus.loading => const MovieListLoading(),
                      MovieListLoadStatus.error => MovieListError(
                          message: vm.message,
                          onRetry: () =>
                              context.read<MovieListViewModel>().reload(),
                        ),
                      MovieListLoadStatus.empty => const MovieListEmpty(),
                      MovieListLoadStatus.success => RefreshIndicator(
                          // 로딩 중에는 새로고침이 동작하지 않는다.
                          onRefresh: () =>
                              context.read<MovieListViewModel>().refresh(),
                          child: GridView.builder(
                            // 목록이 짧아도 아래로 당겨서 새로고침할 수 있게 한다.
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: vm.movies.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.6,
                            ),
                            itemBuilder: (context, index) {
                              final movie = vm.movies[index];
                              return MovieCard(
                                movie: movie,
                                genreLabel: _genreName(vm.genres, movie),
                              );
                            },
                          ),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
