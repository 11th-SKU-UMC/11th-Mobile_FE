import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        '내 프로필',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      elevation: 10,
      scrolledUnderElevation: 0,
      shadowColor: AppColors.warmWhite,
      surfaceTintColor: AppColors.warmWhite,
    );
  }
}
