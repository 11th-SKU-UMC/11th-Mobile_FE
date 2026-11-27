// 그냥 바디를 따로 만들었어

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/ProfileScreens/ProfileBody/ProfileHeader.dart';
import 'package:movielog/ProfileScreens/ProfileBody/ProfileStats.dart';
import 'package:movielog/ProfileScreens/ProfileBody/EditProfileButton.dart';
import 'package:movielog/data/models/member_info.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key, required this.member});

  final MemberInfo member; // 8주차: GET /v8/members/me 결과

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16), // ← 좌우 여백
      child: Column(
        children: [
          ProfileHeader(member: member),
          const EditProfileButton(),
          const ProfileStats(),
          const SizedBox(height: 24),

          // 8주차: 현재 로그인 세션에서 등록한 평점 (토큰 기반 수정·삭제)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: AppColors.SecondaryScale300,
                width: 1.5,
              ),
            ),
            tileColor: AppColors.white,
            title: const Text(
              '내가 등록한 평점',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 30,
            ),
            onTap: () => context.push('/my/ratings'),
          ),
          const SizedBox(height: 12),

          // 9주차: 내가 등록한 평점 아래에 내 즐겨찾기 행
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: AppColors.SecondaryScale300,
                width: 1.5,
              ),
            ),
            tileColor: AppColors.white,
            title: const Text(
              '내 즐겨찾기',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 30,
            ),
            onTap: () => context.push('/my/favorites'),
          ),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
