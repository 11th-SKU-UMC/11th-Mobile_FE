import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 마이페이지 상단 프로필. GET me로 받은 닉네임·이메일·가입일을 보여준다.
///
/// 사진은 기존 디자인 예시 이미지다. (v7 GET me에는 프로필 사진이 없다)
/// [onEditPressed]가 null이면(내 정보를 아직 못 받았으면) 수정 버튼이 비활성화된다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.imagePath,
    required this.nickname,
    this.email,
    this.joinedText,
    required this.onEditPressed,
  });

  final String imagePath;
  final String nickname;
  final String? email;

  /// 예: `2026.10.10 가입`
  final String? joinedText;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final email = this.email;
    final joinedText = this.joinedText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            imagePath,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          nickname,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (joinedText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            joinedText,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        if (email != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            email,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: onEditPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(
              color: onEditPressed == null
                  ? colors.outlineVariant
                  : colors.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }
}
