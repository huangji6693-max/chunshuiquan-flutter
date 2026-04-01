import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'frosted_nav_bar.dart';

/// 主页面脚手架 - 包含底部导航栏
/// 5个tab：发现 / 附近 / 匹配 / 通知 / 我的
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/nearby')) return 1;
    if (loc.startsWith('/moments')) return 2;
    if (loc.startsWith('/matches') || loc.startsWith('/chat')) return 3;
    if (loc.startsWith('/profile') || loc.startsWith('/settings') ||
        loc.startsWith('/coins') || loc.startsWith('/vip') ||
        loc.startsWith('/gifts') || loc.startsWith('/verification') ||
        loc.startsWith('/notifications') || loc.startsWith('/likes')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: FrostedNavBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/discover');
            case 1: context.go('/nearby');
            case 2: context.go('/moments');
            case 3: context.go('/matches');
            case 4: context.go('/profile');
          }
        },
      ),
    );
  }
}
