import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 홈·영화·마이 탭의 공통 틀. NavigationBar를 한 번만 만들고 body만 탭에 따라 바뀐다.
///
/// [StatefulNavigationShell]은 탭마다 독립된 Navigator를 들고 있어서
/// 다른 탭에 갔다 와도 각 탭의 스크롤 위치와 필터 상태가 그대로 남는다.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    // 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 탭 화면(홈 포함)에서는 뒤로 가기로 회원가입 화면 등에 돌아가지 않도록 막는다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.movie_outlined),
              selectedIcon: Icon(Icons.movie),
              label: '영화',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }
}
