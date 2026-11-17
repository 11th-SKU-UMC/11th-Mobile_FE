import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 화면 위에 어두운 ModalBarrier와 중앙 흰색 CircularProgressIndicator만 올리는 오버레이입니다.
/// 흰색 카드나 로딩 문구는 띄우지 않고, 완료 전 터치와 화면 이탈을 막습니다.
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
