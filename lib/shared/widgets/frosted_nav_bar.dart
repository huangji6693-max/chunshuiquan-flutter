import 'dart:ui';
import 'package:flutter/material.dart';

/// 毛玻璃底部导航栏
/// 5个tab：发现 / 附近 / 匹配 / 通知 / 我的
class FrostedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  // 图标：(选中, 未选中)
  static const _icons = [
    (Icons.explore, Icons.explore_outlined),
    (Icons.location_on, Icons.location_on_outlined),
    (Icons.dynamic_feed, Icons.dynamic_feed_outlined),
    (Icons.favorite, Icons.favorite_outline),
    (Icons.person, Icons.person_outline),
  ];

  // Tab标签
  static const _labels = ['发现', '附近', '动态', '匹配', '我的'];

  const FrostedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_icons.length, (i) {
                  final selected = i == currentIndex;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: SizedBox(
                      width: 64,
                      height: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: selected
                                ? ShaderMask(
                                    key: const ValueKey(true),
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                                    ).createShader(bounds),
                                    child: Icon(
                                      _icons[i].$1,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    key: const ValueKey(false),
                                    _icons[i].$2,
                                    size: 24,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              color: selected
                                  ? const Color(0xFFFF4D88)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
