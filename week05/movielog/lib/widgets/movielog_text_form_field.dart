import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_spacing.dart';

/// 라벨, 입력창, 상태 아이콘(오류/성공), 비밀번호 표시 토글을 묶은 공통 입력 위젯.
///
/// 입력값의 유효 여부에 따라 오른쪽 아이콘과 배경색이 바뀐다.
/// 검증 규칙([validator])과 다른 화면 상태 갱신([onChanged])은 부모가 넘겨준다.
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

    final hasError =
        _touched && widget.validator(widget.controller.text) != null;
    final isValid = _touched && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscured,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: textTheme.bodyMedium,
          validator: widget.validator,
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
            suffixIcon: _buildSuffix(
              context,
              hasError: hasError,
              isValid: isValid,
            ),
          ),
        ),
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
