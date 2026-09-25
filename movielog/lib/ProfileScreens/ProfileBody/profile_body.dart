// 그냥 바디를 따로 만들었어

import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/ProfileScreens/ProfileBody/ProfileHeader.dart';
import 'package:movielog/ProfileScreens/ProfileBody/ProfileStats.dart';
import 'package:movielog/ProfileScreens/ProfileBody/EditProfileButton.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // ← 좌우 여백
      child: Column(
        children: [
          const ProfileHeader(),
          const EditProfileButton(),
          const ProfileStats(),
          const SizedBox(height: 32),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '선호하는 장르',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ),

          SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text(
                    '드라마',
                    style: TextStyle(
                      color: AppColors.primaryScale600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.primaryScale200,
                  side: BorderSide(color: AppColors.primaryScale200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Chip(
                  label: const Text(
                    'SF',
                    style: TextStyle(
                      color: AppColors.primaryScale600,
                      fontWeight: FontWeight.w600,
                    ), // ← 글자 색
                  ),
                  backgroundColor: AppColors.primaryScale200,
                  side: BorderSide(color: AppColors.primaryScale200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Chip(
                  label: const Text(
                    '애니메이션',
                    style: TextStyle(
                      color: AppColors.primaryScale600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.primaryScale200,
                  side: BorderSide(color: AppColors.primaryScale200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
