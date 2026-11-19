import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

/// 홈·영화·마이 탭이 공유하는 레이아웃입니다.
/// body에는 ShellRoute가 전달한 child만 바뀌어 들어오므로 NavigationBar는 한 번만 만들어집니다.
///
/// 탭을 바꿔도 이 State는 유지되므로, 어느 탭으로 진입하든 내 정보(GET me)를 여기서 한 번 불러옵니다.
/// 로그아웃 뒤 다시 로그인하면 새로 만들어져 다시 호출합니다.
class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _locations = ['/home', '/movies', '/my'];

  @override
  void initState() {
    super.initState();
    // 첫 build 중에 notifyListeners()가 실행되지 않도록 다음 프레임에 호출합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.currentIndex,
        height: 64,
        onDestinationSelected: (index) => context.go(_locations[index]),
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
    );
  }
}
