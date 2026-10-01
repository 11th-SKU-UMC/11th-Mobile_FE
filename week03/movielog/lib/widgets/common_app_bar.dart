import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.centerTitle = false,
    this.leading,
    this.titleStyle,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final bool centerTitle;
  final Widget? leading;
  final TextStyle? titleStyle;
  final List<Widget>? actions;

  /// false면 이전 화면이 있어도 자동 뒤로 가기 버튼을 만들지 않는다.
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      leading: leading,
      titleTextStyle: titleStyle,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
