import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;
  int _resetCount = 0;

  bool get _canSubmit => _rating > 0;

  void _reset() {
    setState(() {
      _rating = 0;
      _resetCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('영화는 어떠셨나요?', style: AppTextStyles.titleLarge),
            const SizedBox(height: 24),
            MovieRatingInput(
              key: ValueKey(_resetCount),
              rating: _rating,
              onChanged: (value) {
                setState(() => _rating = value);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _canSubmit ? _reset : null,
              style: TextButton.styleFrom(foregroundColor: AppColors.violet),
              child: const Text(
                '다시 선택하기',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _canSubmit ? () => Navigator.pop(context, _rating) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  disabledBackgroundColor: AppColors.violet.withAlpha(100),
                  foregroundColor: AppColors.white,
                  disabledForegroundColor: AppColors.white.withAlpha(200),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}