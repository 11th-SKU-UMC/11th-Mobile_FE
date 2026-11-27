import 'package:flutter/material.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

// 목록 아래: 더 보기 / 추가 로딩 / 같은 page 재시도 / 끝
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({super.key, required this.vm, this.label = '더 보기'});

  final PagedMoviesViewModel vm;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasMore && !vm.isLoadingMore && vm.loadMoreError == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '더 이상 조회할 페이지가 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (vm.loadMoreError != null) ...[
            Text(
              vm.loadMoreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
          ],
          MovieLogButton(
            width: double.infinity,
            label: vm.loadMoreError == null ? label : '다음 페이지 다시 시도',
            isLoading: vm.isLoadingMore, // 요청 중 비활성화 + 로딩
            onPressed: vm.phase == LoadPhase.ready ? vm.loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
