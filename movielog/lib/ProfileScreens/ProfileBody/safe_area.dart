// 노치 영역임

import 'package:flutter/material.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/ProfileScreens/ProfileBody/profile_body.dart';

class ProfileScreenBody extends StatelessWidget {
  const ProfileScreenBody({super.key, required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16),
      child: ProfileBody(member: member),
    );
  }
}
