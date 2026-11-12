import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 별점(1~5 정수)과 코멘트를 입력받고, 저장 로직은 [onSubmit] 콜백으로 받아 실행합니다.
///
/// - [onSubmit]이 예외 없이 끝나면 true를 반환하며 닫힙니다.
/// - 취소하면 [onSubmit]을 호출하지 않고 false를 반환합니다.
/// - [onSubmit]이 예외를 던지면 Dialog를 유지하고 입력값을 보존한 채 오류를 보여줍니다.
///   [StateError]의 message는 사용자 안내 문구로 그대로 표시합니다.
/// - 저장 중에는 PopScope로 뒤로가기를 막습니다. 바깥 탭은 showDialog 호출부에서
///   barrierDismissible: false로 함께 막아야 합니다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.onSubmit,
    this.movieTitle,
    this.initialScore = 0,
    this.initialComment,
  });

  final Future<void> Function(int score, String? comment) onSubmit;
  final String? movieTitle;
  final int initialScore;
  final String? initialComment;

  static const maxCommentLength = 500;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;

  // build 안에서 만들면 setState마다 입력하던 코멘트가 초기화되므로 State에서 한 번만 만듭니다.
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
    final trimmed = _commentController.text.trim();
    if (trimmed.length > RatingDialog.maxCommentLength) {
      setState(() => _errorText = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      // 실패해도 반드시 로딩을 해제해야 다시 시도할 수 있습니다.
      setState(() {
        _isSubmitting = false;
        _errorText = error is StateError
            ? error.message
            : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.movieTitle;

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('영화는 어떠셨나요?', style: AppTextStyles.titleLarge),
              if (title != null && title.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              const SizedBox(height: 20),
              MovieRatingInput(
                rating: _score.toDouble(),
                enabled: !_isSubmitting,
                onChanged: (value) =>
                    setState(() => _score = validateServerScore(value)),
              ),
              const SizedBox(height: 8),
              Text(
                _score == 0 ? '별을 눌러 평점을 선택해 주세요' : '$_score점',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 3,
                maxLength: RatingDialog.maxCommentLength,
                decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MovieLogButton(
                      label: '평점 저장',
                      width: double.infinity,
                      isLoading: _isSubmitting,
                      // 별점을 선택하지 않았다면 코멘트가 있어도 저장할 수 없습니다.
                      onPressed: _score > 0 ? _onConfirm : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
