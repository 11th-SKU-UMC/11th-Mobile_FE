import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 앱 전체에서 쓰는 공용 버튼.
///
/// - 기본: [onPressed]가 있고 [isLoading]이 false
/// - 통신 중: [isLoading]이 true. 회색으로 비활성화되고 가운데 인디케이터만 그린다.
/// - 비활성: [onPressed]가 null. 조건이 충족되지 않아 누를 수 없다.
///
/// [width]는 SizedBox 규칙을 그대로 따른다.
/// - null: label 길이에 맞는 내용 기반 크기 (입력창 옆 보조 버튼)
/// - double.infinity: 부모가 허용하는 최대 너비 (Form 하단 제출 버튼)
/// - 고정 값: 항상 같은 크기
///
/// 버튼은 상태를 표시만 하고 스스로 바꾸지 않는다. 상태 결정은 ViewModel이 한다.
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          // 통신 중은 회색, 조건 미충족 비활성은 2주차 디자인의 연보라색으로 구분한다.
          disabledBackgroundColor: isLoading
              ? AppColors.outlineVariant
              : AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: Size(0, height),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        // label과 인디케이터를 동시에 그리지 않고 하나만 고른다.
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
