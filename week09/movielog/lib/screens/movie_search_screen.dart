import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/paged_movies_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/paged_movie_results.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _submit(value);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _submit(value);
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    context.read<PagedMoviesViewModel>().submitQuery(value);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화 검색',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/movies'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '영화 제목을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onChanged,
                onSubmitted: _submit,
              ),
            ),
            Expanded(
              child: PagedMovieResults(
                viewModel: viewModel,
                idleMessage: '검색어를 입력해 주세요.',
                emptyMessage: '검색 결과가 없습니다.',
                errorMessage: '검색 결과를 불러오지 못했습니다.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
