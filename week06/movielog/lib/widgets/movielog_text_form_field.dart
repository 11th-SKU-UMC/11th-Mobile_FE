import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_spacing.dart';

/// 라벨, 입력창, 상태 아이콘(오류/성공), 비밀번호 표시 토글을 묶은 공통 입력 위젯.
///
/// 입력값의 유효 여부에 따라 오른쪽 아이콘과 배경색이 바뀐다.
/// 검증 규칙([validator])과 다른 화면 상태 갱신([onChanged])은 부모가 넘겨준다.
///
/// [validator]는 형식만 검사한다. 서버 검증 결과(예: 중복)는 [errorText]로 받아
/// 형식이 맞아도 입력창을 에러 상태로 보여준다. [trailing]은 입력창 오른쪽에
/// Row 형제로 8px 간격을 두고 배치한다(예: 중복 확인 버튼).
class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enableVisibilityToggle = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.errorText,
    this.successText,
    this.trailing,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enableVisibilityToggle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  /// 형식 검증과 별개인 외부(서버) 오류 문구. null이 아니면 validator 결과보다 우선한다.
  /// (ViewModel은 형식이 맞는 값에 대해서만 이 문구를 만든다.)
  final String? errorText;

  /// 입력창 아래에 보여줄 안내 문구(예: 사용 가능한 닉네임). 오류가 있으면 숨긴다.
  final String? successText;

  /// 입력창 오른쪽에 둘 Widget. 입력창과 같은 Row의 형제가 된다.
  final Widget? trailing;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  static const double _iconSize = 20;

  /// 오류 문구는 기본적으로 입력창 안쪽 여백(16)과 간격(4)만큼 들어가 있다.
  /// 디자인은 입력창 왼쪽 끝에 맞추므로 그만큼 왼쪽으로 당긴다.
  static const double _errorTextInset = 20;

  late bool _obscured = widget.obscureText;
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasFormatError =
        _touched && widget.validator(widget.controller.text) != null;
    final hasError = hasFormatError || widget.errorText != null;
    final isValid = _touched && !hasError;
    final successText = hasError ? null : widget.successText;

    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscured,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: textTheme.bodyMedium,
      validator: widget.validator,
      // 외부(서버) 오류 문구. errorBuilder와 decoration.errorText는 함께 쓸 수 없어서
      // forceErrorText로 넘긴다. 같은 errorBuilder 모양으로 그려진다.
      forceErrorText: widget.errorText,
      errorBuilder: (context, errorText) => Transform.translate(
        offset: const Offset(-_errorTextInset, 0),
        child: Text(errorText),
      ),
      onChanged: (value) {
        _touched = true;
        widget.onChanged?.call(value);
      },
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        fillColor: hasError ? colors.errorContainer : null,
        suffixIconConstraints: const BoxConstraints(),
        suffixIcon: _buildSuffix(context, hasError: hasError, isValid: isValid),
      ),
    );
    final trailing = widget.trailing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (trailing == null)
          field
        else
          Row(
            // 오류 문구로 입력창 높이가 늘어나도 버튼은 입력창 윗줄에 맞춘다.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field),
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ),
        if (successText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            successText,
            style: textTheme.bodySmall?.copyWith(color: colors.primary),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix(
    BuildContext context, {
    required bool hasError,
    required bool isValid,
  }) {
    final colors = Theme.of(context).colorScheme;

    final statusIcon = hasError
        ? SvgPicture.asset(
            'assets/icons/error.svg',
            width: _iconSize,
            height: _iconSize,
            colorFilter: ColorFilter.mode(colors.error, BlendMode.srcIn),
          )
        : isValid
        ? Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 14, color: colors.onPrimary),
          )
        : null;

    final visibilityToggle = widget.enableVisibilityToggle
        ? IconButton(
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: _obscured ? '비밀번호 표시' : '비밀번호 숨기기',
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: SvgPicture.asset(
              _obscured
                  ? 'assets/icons/visibility_off.svg'
                  : 'assets/icons/visibility.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                colors.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
          )
        : null;

    if (statusIcon == null && visibilityToggle == null) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?statusIcon,
          if (statusIcon != null && visibilityToggle != null)
            const SizedBox(width: AppSpacing.sm),
          ?visibilityToggle,
        ],
      ),
    );
  }
}
