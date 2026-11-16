import 'package:flutter/material.dart';

class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.onRetry,
    this.message,
  });

  // 버튼을 눌렀을 때 실행할 함수는 화면(부모)이 정해서 넘겨줌
  final VoidCallback onRetry;

  // ViewModel이 알려주는 오류 문구 (없으면 기본 문구)
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message ?? '영화를 불러오지 못했습니다.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
