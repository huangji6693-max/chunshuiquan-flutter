import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'frosted_nav_bar.dart';

/// 主页面脚手架 - 包含底部导航栏
/// 4个tab：发现 / 匹配 / 通知 / 我的
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/matches') || loc.startsWith('/chat')) return 1;
    if (loc.startsWith('/notifications')) return 2;
    if (loc.startsWith('/profile') || loc.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      extendBody: true, // 关键：内容延伸到毛玻璃下方
      body: child,
      bottomNavigationBar: FrostedNavBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/discover');
            case 1: context.go('/matches');
            case 2: context.go('/notifications');
            case 3: context.go('/profile');
          }
        },
      ),
    );
  }
}
