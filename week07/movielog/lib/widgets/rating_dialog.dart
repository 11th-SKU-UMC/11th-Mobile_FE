import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_spacing.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 별점(1~5 정수)과 코멘트를 입력받아 저장까지 실행하는 Dialog.
///
/// 저장 로직은 [onSubmit]으로 받아 Dialog 안에서 실행한다.
/// - [onSubmit]이 예외 없이 끝나면 true를 돌려주고 닫힌다.
/// - 취소하면 [onSubmit]을 부르지 않고 false를 돌려준다. (API 요청 없음)
/// - [onSubmit]이 예외를 던지면 닫히지 않고 오류 문구를 보여준다. 입력은 그대로 남는다.
/// - 저장 중에는 PopScope와 barrierDismissible: false로 Dialog가 닫히지 않는다.
///
/// 띄울 때는 [RatingDialog.show]를 쓴다. (barrierDismissible: false가 항상 들어간다)
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.movieTitle,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  static const int maxCommentLength = 500;
  static const String defaultErrorMessage = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  final String? movieTitle;

  /// 수정할 때의 기존 별점. 처음이면 0(미선택).
  final int initialScore;

  /// 수정할 때의 기존 코멘트. null이면 빈 칸으로 시작한다.
  final String? initialComment;

  /// 저장 요청. 실패하면 예외를 던져야 한다.
  final Future<void> Function(int score, String? comment) onSubmit;

  static Future<bool?> show(
    BuildContext context, {
    String? movieTitle,
    int initialScore = 0,
    String? initialComment,
    required Future<void> Function(int score, String? comment) onSubmit,
  }) {
    return showDialog<bool>(
      context: context,
      // PopScope는 뒤로가기만 막으므로 바깥 탭으로 닫히는 것도 함께 막는다.
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        movieTitle: movieTitle,
        initialScore: initialScore,
        initialComment: initialComment,
        onSubmit: onSubmit,
      ),
    );
  }

  /// onSubmit이 던진 예외를 사용자 문구로 바꾼다.
  static String messageOf(Object error) {
    if (error is DioException) return writeErrorMessage(error);
    if (error is StateError) return error.message;
    return defaultErrorMessage;
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;

  /// build()에서 만들면 setState마다 입력이 초기화되므로 State에서 한 번만 만든다.
  late final TextEditingController _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  /// 초기화할 때마다 올려서 [MovieRatingInput]을 새로 만든다.
  /// (RatingBar는 처음 값만 읽기 때문에 Key를 바꿔야 빈 별로 다시 그려진다.)
  int _resetCount = 0;

  bool get _hasScore => _score > 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _score = 0;
      _resetCount++;
    });
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
      // 실패 시 로딩을 반드시 되돌려야 다시 시도할 수 있다.
      setState(() {
        _isSubmitting = false;
        _errorText = RatingDialog.messageOf(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final movieTitle = widget.movieTitle;

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
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
              if (movieTitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  movieTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              MovieRatingInput(
                key: ValueKey(_resetCount),
                rating: _score.toDouble(),
                allowHalfRating: false,
                enabled: !_isSubmitting,
                onChanged: (value) =>
                    setState(() => _score = validateServerScore(value)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _hasScore
                    ? '$_score / ${MovieRatingInput.maxRating}'
                    : '별을 눌러 평점을 선택해주세요',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _hasScore && !_isSubmitting ? _reset : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('초기화하고 다시 선택하기'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 3,
                maxLength: RatingDialog.maxCommentLength,
                decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    // 별점을 고르기 전에는 코멘트가 있어도 저장할 수 없다.
                    child: MovieLogButton(
                      label: '확인',
                      height: 48,
                      isLoading: _isSubmitting,
                      onPressed: _hasScore ? _onConfirm : null,
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
