// 공용 AppBar에서 조금 수정한 파일
// Scaffold는 화면 전체를 차지하는 위젯임
// Scaffold는 AppBar, Body, BottomNavigationBar 등으로 구성됨.
// 따라서 Scaffold는 profile_screen.dart에서 AppBar를 제외한 나머지 영역을 담당함.
// 그래서 profile_screen.dart에서 Scaffold를

import 'package:flutter/material.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/ProfileScreens/ProfileBody/profile_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(
        title: '내 프로필',
        titleStyle: AppTextStyles.titleAppBar,
      ),
      body: const ProfileBody(),
    );
  }
}

// 특정 화면에서, 다른 스타일을 사용하고 싶으면, 앱 바는 다음과 같이 사용
/* CommonAppBar(
  title: '영화 상세',
  centerTitle: true,
  titleStyle: AppTextStyles.titleLarge.copyWith(
    color: AppColors.black,
  ),
) */
