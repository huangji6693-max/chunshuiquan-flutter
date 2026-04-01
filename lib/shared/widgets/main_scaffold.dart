import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'frosted_nav_bar.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/nearby/presentation/nearby_screen.dart';
import '../../features/moments/presentation/moments_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// 主页面脚手架 — IndexedStack 保持 5 个 tab 页面状态
/// 切换时不重建，避免抖动和数据重载
class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // 5个主tab页面，用 IndexedStack 保活
  final _tabs = const [
    DiscoverScreen(),
    NearbyScreen(),
    MomentsScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  // 记录哪些 tab 已经被访问过（懒加载）
  final _visited = <int>{0};

  int _indexFromLocation(BuildContext context) {
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

  bool _isSubPage(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    // 子页面（聊天、设置、金币等）不用 IndexedStack，直接显示 child
    return loc.startsWith('/chat/') ||
        loc.startsWith('/call/') ||
        loc.startsWith('/settings') ||
        loc.startsWith('/coins') ||
        loc.startsWith('/vip') ||
        loc.startsWith('/gifts') ||
        loc.startsWith('/verification') ||
        loc.startsWith('/notifications') ||
        loc.startsWith('/likes') ||
        loc.startsWith('/moments/create');
  }

  @override
  Widget build(BuildContext context) {
    final locIndex = _indexFromLocation(context);
    final isSubPage = _isSubPage(context);

    // 如果不是子页面，更新当前tab index
    if (!isSubPage && locIndex != _currentIndex) {
      _currentIndex = locIndex;
      _visited.add(_currentIndex);
    }

    return Scaffold(
      extendBody: true,
      body: isSubPage
          // 子页面直接渲染 GoRouter 的 child
          ? widget.child
          // 主 tab 用 IndexedStack 保活 + 淡入过渡
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: IndexedStack(
                key: ValueKey(_currentIndex),
                index: _currentIndex,
                children: List.generate(5, (i) {
                  if (_visited.contains(i)) return _tabs[i];
                  return const SizedBox.shrink();
                }),
              ),
            ),
      bottomNavigationBar: FrostedNavBar(
        currentIndex: isSubPage ? locIndex : _currentIndex,
        onTap: (i) {
          if (i == _currentIndex && !isSubPage) return; // 避免重复点击
          setState(() {
            _currentIndex = i;
            _visited.add(i);
          });
          // 同步更新路由（用于深层导航返回时定位）
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
