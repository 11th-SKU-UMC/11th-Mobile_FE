import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// '필수 약관에 동의합니다' 체크박스 한 줄.
///
/// 체크박스뿐 아니라 글자를 눌러도 값이 바뀐다.
/// 값은 부모가 들고 있고, 이 위젯은 [onChanged]로 새 값을 알려주기만 한다.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.boxSize = 24,
  });

  /// Checkbox가 그리는 기본 정사각형 한 변(논리 픽셀). 디자인 크기에 맞추려면 이 값을 기준으로 키운다.
  static const double _materialCheckboxSize = 18;

  final bool value;
  final ValueChanged<bool> onChanged;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          SizedBox(
            width: boxSize,
            height: boxSize,
            child: Transform.scale(
              scale: boxSize / _materialCheckboxSize,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('필수 약관에 동의합니다', style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
