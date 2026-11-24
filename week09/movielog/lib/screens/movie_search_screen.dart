import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/movielog_button.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final text = TextEditingController();

  String submittedQuery = '';
  String? inputError;

  // [Challenge A] debounce용 타이머. Required만 한다면 이 변수와 _onChanged는 지워도 됩니다.
  Timer? _debounce;

  // 제출(키보드 검색 / 아이콘)할 때 호출합니다. 빈 검색어는 서버에 보내지 않습니다.
  void submitSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() => inputError = '검색어를 입력합니다.');
      return;
    }

    setState(() {
      inputError = null;
      submittedQuery = query;
    });

    // 새 검색은 항상 page 1부터. 이전 응답은 ViewModel의 generation이 걸러냅니다.
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  // [Challenge A] 입력이 500ms 멈춘 뒤 마지막 검색어로 한 번만 검색합니다.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final query = value.trim();
      if (query.isEmpty) return; // 빈 검색어는 서버에 보내지 않습니다.
      if (query == submittedQuery) return; // 같은 검색어 중복 요청 방지
      submitSearch(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('영화 검색'), centerTitle: true),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged, // [Challenge A]
                      onSubmitted: submitSearch,
                      decoration: InputDecoration(
                        labelText: '검색어',
                        errorText: inputError,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => submitSearch(text.text),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<PagedMoviesViewModel>(
                builder: (context, vm, _) {
                  if (vm.phase == LoadPhase.idle) {
                    return const Center(child: Text('검색어를 입력합니다.'));
                  }

                  if (vm.phase == LoadPhase.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (vm.phase == LoadPhase.error) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(vm.errorMessage ?? '조회 오류입니다.'),
                          MovieLogButton(
                            label: '다시 시도',
                            onPressed: () =>
                                vm.loadInitial(query: submittedQuery),
                          ),
                        ],
                      ),
                    );
                  }

                  if (vm.phase == LoadPhase.empty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  return ListView.builder(
                    itemCount: vm.movies.length + 1,
                    itemBuilder: (context, index) {
                      if (index == vm.movies.length) {
                        return MoviePageFooter(vm: vm);
                      }

                      final movie = vm.movies[index];

                      return ListTile(
                        title: Text(movie.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onOpenMovie(movie),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}
