import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/movie_page_footer.dart';
import 'package:movielog/widgets/movie_row_card.dart';
import 'package:movielog/widgets/movielog_button.dart';

// 영화 검색 (/movies/search) — 영화 목록과 별도의 PagedMoviesViewModel 사용
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final text = TextEditingController();
  Timer? _debounce; // Challenge A: 입력이 500ms 멈추면 자동 검색

  String submittedQuery = '';
  String? inputError;

  // 제출(키보드 검색·검색 버튼): 빈 검색어는 서버에 보내지 않습니다.
  void submitSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => inputError = '검색어를 입력합니다.');
      return;
    }
    _search(query);
  }

  // Challenge A: 입력할 때마다 이전 타이머를 취소하고 500ms 타이머를 새로 시작합니다.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final query = value.trim();
      if (query.isEmpty) return; // 빈 검색어는 요청하지 않습니다.
      if (query == submittedQuery) return; // 같은 검색어는 다시 요청하지 않습니다.
      _search(query);
    });
  }

  void _search(String query) {
    setState(() {
      inputError = null;
      submittedQuery = query;
    });
    // 새 검색은 page 1부터. 이전 검색어의 늦은 응답은 generation이 버립니다.
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    text.dispose();
    super.dispose();
  }

  String? _year(TmdbMovieDto movie) {
    final date = movie.releaseDate;
    return (date != null && date.length >= 4) ? date.substring(0, 4) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 검색', style: AppTextStyles.titleAppBar),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: text,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: submitSearch,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: '영화 제목을 입력하세요',
                errorText: inputError,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.NeutralScale600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.NeutralScale600),
                ),
                suffixIcon: TextButton(
                  onPressed: () => submitSearch(text.text),
                  child: const Text(
                    '검색',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, vm, _) {
                switch (vm.phase) {
                  case LoadPhase.idle:
                    return const Center(child: Text('검색어를 입력합니다.'));
                  case LoadPhase.loading:
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  case LoadPhase.error:
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vm.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          MovieLogButton(
                            label: '다시 시도',
                            width: 220,
                            onPressed: () =>
                                vm.loadInitial(query: submittedQuery),
                          ),
                        ],
                      ),
                    );
                  case LoadPhase.empty:
                    return const Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  case LoadPhase.ready:
                    return ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: vm.movies.length + 1,
                      itemBuilder: (context, index) {
                        if (index == vm.movies.length) {
                          return MoviePageFooter(vm: vm, label: '검색 결과 더 보기');
                        }
                        final movie = vm.movies[index];
                        return MovieRowCard(
                          title: movie.title,
                          posterPath: movie.posterPath,
                          subtitle: _year(movie),
                          onTap: () => widget.onOpenMovie(movie),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
