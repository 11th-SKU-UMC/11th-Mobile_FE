import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/api_error.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

typedef RatingDialogResult = ({bool saved, String? error});

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    this.showAddToFavorite = false,
    this.closeOnSubmitError = false,
    required this.onSubmit,
  });
  final int initialScore;
  final String? initialComment;
  final bool showAddToFavorite;
  final bool closeOnSubmitError;
  final Future<void> Function(int score, String? comment, bool addToFavorites)
  onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  bool _addToFavorites = false;
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
      await widget.onSubmit(
        _score,
        comment,
        widget.showAddToFavorite && _addToFavorites,
      );
      if (!mounted) return;
      Navigator.pop<RatingDialogResult>(context, (saved: true, error: null));
    } catch (error) {
      if (!mounted) return;
      final code = apiErrorCode(error);
      final message = switch (code) {
        'COMMON400' => apiErrorMessage(error, fallback: '별점과 코멘트를 확인해 주세요.'),
        'FAVORITE409_1' => '이미 즐겨찾기에 등록된 영화입니다.',
        'MEMBER404_1' => '회원 정보를 찾을 수 없습니다.',
        _ => ratingErrorMessage(error),
      };
      if (widget.closeOnSubmitError &&
          const {
            'RATING409_1',
            'FAVORITE409_1',
            'MEMBER404_1',
          }.contains(code)) {
        Navigator.pop<RatingDialogResult>(context, (
          saved: false,
          error: message,
        ));
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorText = message;
      });
      if (const {'RATING403_1', 'RATING404_1', 'RATING409_1'}.contains(code)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText!)));
      }
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
              if (widget.showAddToFavorite)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('즐겨찾기에도 추가'),
                  value: _addToFavorites,
                  onChanged: _isSubmitting
                      ? null
                      : (value) =>
                            setState(() => _addToFavorites = value ?? false),
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
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
