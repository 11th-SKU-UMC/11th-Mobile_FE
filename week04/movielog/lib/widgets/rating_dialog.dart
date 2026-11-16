import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'movie_rating_input.dart';

/// 별점을 고르는 커스텀 Dialog.
///
/// '확인'을 누르면 고른 별점을, '취소'나 바깥을 누르면 null을 돌려준다.
/// 별점을 고르기 전에는 '확인'이 비활성화되고, '초기화'로 다시 고를 수 있다.
///
/// 띄울 때는 [RatingDialog.show]를 쓴다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.movieTitle,
    this.initialRating = 0,
  });

  final String movieTitle;

  /// 이전에 남긴 별점. 처음이면 0.
  final double initialRating;

  static Future<double?> show(
    BuildContext context, {
    required String movieTitle,
    double initialRating = 0,
  }) {
    return showDialog<double>(
      context: context,
      builder: (dialogContext) =>
          RatingDialog(movieTitle: movieTitle, initialRating: initialRating),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating;

  /// 초기화할 때마다 올려서 [MovieRatingInput]을 새로 만든다.
  /// (RatingBar는 처음 값만 읽기 때문에 Key를 바꿔야 빈 별로 다시 그려진다.)
  int _resetCount = 0;

  bool get _hasRating => _rating > 0;

  void _reset() {
    setState(() {
      _rating = 0;
      _resetCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          // Dialog가 화면 전체 높이가 아니라 내용만큼만 커지도록 한다.
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '영화는 어떠셨나요?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.movieTitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MovieRatingInput(
              key: ValueKey(_resetCount),
              rating: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _hasRating
                  ? '$_rating / ${MovieRatingInput.maxRating}'
                  : '별을 눌러 평점을 선택해주세요',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _hasRating ? _reset : null,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('초기화하고 다시 선택하기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: ElevatedButton(
                    // 별점을 고르기 전에는 저장할 수 없다.
                    onPressed: _hasRating
                        ? () => Navigator.of(context).pop(_rating)
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
