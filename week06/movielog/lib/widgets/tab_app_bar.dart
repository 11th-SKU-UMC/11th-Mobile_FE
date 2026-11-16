import 'package:flutter/material.dart';

import 'common_app_bar.dart';

/// 하단 탭(홈·영화·마이) 화면의 상단 바.
///
/// 탭의 첫 화면이라 뒤로 가기 버튼이 없고, 제목은 왼쪽에 브랜드 색으로 표시한다.
class TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TabAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CommonAppBar(
      title: title,
      automaticallyImplyLeading: false,
      actions: actions,
      titleStyle: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
