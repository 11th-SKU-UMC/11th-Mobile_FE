import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.imagePath,
    required this.nickname,
    required this.bio,
    required this.onEditPressed,
  });

  final String imagePath;
  final String nickname;
  final String bio;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

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
        const SizedBox(height: AppSpacing.sm),
        Text(
          bio,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: onEditPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
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
