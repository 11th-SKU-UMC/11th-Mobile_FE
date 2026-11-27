import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

/// 목록 아래의 "더 보기" / 추가 로딩 / 다음 page 오류·재시도 / 끝 표시.
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({super.key, required this.vm});

  static const String endMessage = '더 이상 조회할 페이지가 없습니다.';
  static const String loadMoreLabel = '더 보기';
  static const String retryLabel = '다음 페이지 다시 시도';

  final PagedMoviesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!vm.hasMore && !vm.isLoadingMore && vm.loadMoreError == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          endMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }

    final error = vm.loadMoreError;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            Text(
              error,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          MovieLogButton(
            width: double.infinity,
            label: error == null ? loadMoreLabel : retryLabel,
            isLoading: vm.isLoadingMore,
            onPressed: vm.phase == LoadPhase.ready ? vm.loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
