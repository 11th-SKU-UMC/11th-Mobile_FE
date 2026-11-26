import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_text_styles.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_page_footer.dart';

/// 영화 검색 화면(`/movies/search`)입니다. 영화 목록과 별도의 [PagedMoviesViewModel]을 씁니다.
///
/// - 검색어를 제출하거나(Required) 입력을 500ms 멈추면(Challenge debounce) 검색합니다.
/// - 빈 검색어는 서버에 보내지 않습니다.
/// - 새 검색은 이전 결과를 비우고 page 1부터 시작하며, 이전 검색어의 늦은 응답은 무시합니다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  static const debounceDuration = Duration(milliseconds: 500);

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;
  String? _inputError;

  /// 마지막으로 요청한 검색어입니다. 같은 검색어를 연달아 요청하지 않습니다.
  String _requestedQuery = '';

  void _submitSearch(String value) {
    _debounce?.cancel(); // 제출하면 대기 중인 자동 검색은 필요 없습니다.
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _inputError = '검색어를 입력해 주세요.');
      return;
    }
    if (_inputError != null) setState(() => _inputError = null);
    _search(query, force: true);
  }

  /// Challenge: 입력할 때마다 이전 타이머를 취소하고, 멈춘 뒤 500ms가 지나면 한 번만 검색합니다.
  void _onChanged(String value) {
    if (_inputError != null) setState(() => _inputError = null);
    _debounce?.cancel();
    _debounce = Timer(MovieSearchScreen.debounceDuration, () {
      if (!mounted) return;
      final query = value.trim();
      if (query.isEmpty) return; // 빈 검색어는 서버에 보내지 않습니다.
      _search(query);
    });
  }

  void _search(String query, {bool force = false}) {
    final paged = context.read<PagedMoviesViewModel>();
    // 같은 검색어 결과를 이미 보고 있으면 자동 검색은 다시 요청하지 않습니다. 제출은 항상 요청합니다.
    if (!force && query == _requestedQuery && paged.phase != LoadPhase.error) {
      return;
    }
    _requestedQuery = query;
    paged.loadInitial(query: query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('영화 검색'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로 가기',
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _submitSearch,
                    decoration: InputDecoration(
                      hintText: '영화 제목을 입력해 주세요',
                      prefixIcon: const Icon(Icons.movie_outlined),
                      errorText: _inputError,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '검색',
                  onPressed: () => _submitSearch(_text.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, vm, _) => switch (vm.phase) {
                LoadPhase.idle => const EmptyView(
                  message: '보고 싶은 영화를 검색해 보세요.',
                  icon: Icons.search,
                ),
                LoadPhase.loading => const LoadingView(),
                LoadPhase.error => ErrorView(
                  message: vm.errorMessage,
                  onRetry: vm.refresh,
                ),
                LoadPhase.empty => EmptyView(
                  message: '"${vm.condition.query}" 검색 결과가 없습니다.',
                ),
                LoadPhase.ready => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '"${vm.condition.query}" 검색 결과 ${vm.totalResults}편',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ),
                    Expanded(
                      child: MovieGrid(
                        movies: vm.movies,
                        footer: MoviePageFooter(vm: vm),
                      ),
                    ),
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
