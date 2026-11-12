import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/api_error.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_isSubmitting || _score < 1) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      validateServerScore(_score.toDouble());
      final comment = normalizeComment(_commentController.text);
      await widget.onSubmit(_score, comment);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = apiErrorMessage(
          error,
          fallback: '저장하지 못했습니다. 입력을 확인하고 다시 시도해 주세요.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text(widget.initialScore == 0 ? '평점을 남겨주세요' : '평점 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MovieRatingInput(
                rating: _score.toDouble(),
                enabled: !_isSubmitting,
                onChanged: (value) =>
                    setState(() => _score = validateServerScore(value)),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('rating-comment'),
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '확인',
            isLoading: _isSubmitting,
            onPressed: _score >= 1 && !_isSubmitting ? _onConfirm : null,
          ),
        ],
      ),
    );
  }
}
