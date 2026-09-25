// 노치 영역임

import 'package:flutter/material.dart';

import 'package:movielog/ProfileScreens/ProfileBody/profile_body.dart';

class ProfileScreenBody extends StatelessWidget {
  const ProfileScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      minimum: EdgeInsets.symmetric(horizontal: 16),
      child: ProfileBody(),
    );
  }
}
