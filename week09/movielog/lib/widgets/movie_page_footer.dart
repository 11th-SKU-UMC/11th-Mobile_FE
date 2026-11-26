import 'package:flutter/material.dart';

import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter(this.viewModel, {super.key, required this.autoLoad});

  final PagedMoviesViewModel viewModel;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    final error = viewModel.loadMoreError;
    if (autoLoad &&
        viewModel.hasMore &&
        !viewModel.isLoadingMore &&
        error == null) {
      return const SizedBox(height: 24);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 8),
            ],
            if (viewModel.isLoadingMore)
              const CircularProgressIndicator(semanticsLabel: '다음 영화 불러오는 중')
            else if (viewModel.hasMore)
              MovieLogButton(
                label: error == null ? '더 보기' : '다시 시도',
                onPressed: viewModel.loadNextPage,
              )
            else
              const Text('모든 영화를 불러왔습니다.'),
          ],
        ),
      ),
    );
  }
}
