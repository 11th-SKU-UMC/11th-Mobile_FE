import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

/// 홈·영화·마이 탭의 공통 틀. NavigationBar를 한 번만 만들고 body만 탭에 따라 바뀐다.
///
/// [StatefulNavigationShell]은 탭마다 독립된 Navigator를 들고 있어서
/// 다른 탭에 갔다 와도 각 탭의 스크롤 위치와 필터 상태가 그대로 남는다.
///
/// 어느 탭으로 진입하든 처음 열릴 때 한 번 내 정보(GET me)를 불러와
/// [AuthViewModel.member]에 보관한다. 탭을 바꿔도 이 State는 유지되므로 다시 부르지 않고,
/// 로그아웃 후 다시 로그인하면 새로 만들어져 다시 부른다.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    // loadMember()는 첫 줄에서 notifyListeners()를 부르므로 첫 build 이후에 호출한다.
    // 앱 재시작은 restoreSession()이 이미 member를 채웠으므로 요청하지 않는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().loadMember();
    });
  }

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
