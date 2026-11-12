import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 영화 목록 Error 상태.
///
/// 내부 Exception이나 StackTrace 대신 사용자가 이해할 수 있는 [message]와
/// 할 수 있는 행동('다시 시도')을 보여준다.
class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
