import 'package:flutter/material.dart';

import '../data/services/api_error.dart';
import 'movielog_button.dart';

class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});
  final Future<void> Function() onConfirm;
  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  Future<void> _delete() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = apiErrorMessage(
        error,
        fallback: '삭제하지 못했습니다. 다시 시도해 주세요.',
      );
      setState(() {
        _isDeleting = false;
        _errorText = message;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDeleting,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('삭제한 평점은 복구할 수 없습니다.'),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '삭제',
          isLoading: _isDeleting,
          onPressed: _isDeleting ? null : _delete,
        ),
      ],
    ),
  );
}
