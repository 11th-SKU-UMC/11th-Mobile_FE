import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// v7 GET me 응답(이메일·닉네임·가입일)만 표시합니다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.nickname,
    required this.email,
    required this.joinedText,
    required this.onEdit,
  });

  final String nickname;
  final String email;
  final String joinedText; // 예: "2026.10.10 가입"
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(nickname, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(joinedText, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(email, textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.violet,
              side: const BorderSide(color: AppColors.violet),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('프로필 수정'),
          ),
        ],
      ),
    );
  }
}
