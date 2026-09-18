import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundImage: AssetImage('assets/images/profile.png'),
        ),
        const SizedBox(height: 12),

        const Text(
          '무비러버',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        const Text(
          '좋아하는 영화를 기록하고 있어요',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        SvgPicture.asset(
          'assets/icons/star.svg', // 사용하실 SVG 아이콘 경로로 지정
          width: 24,
          height: 24,
        ),
      ],
    );
  }
}
