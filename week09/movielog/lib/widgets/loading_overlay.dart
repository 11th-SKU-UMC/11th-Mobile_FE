import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 다중 삭제처럼 화면 전체가 기다려야 할 때 child 위에 어두운 막과 흰색 인디케이터만 올립니다.
/// 흰색 카드나 로딩 문구는 띄우지 않습니다.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black45),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
      ],
    );
  }
}
