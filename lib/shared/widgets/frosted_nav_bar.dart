import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

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
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Dt.bgPrimary.withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(
                color: Dt.borderSubtle,
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
                          AnimatedScale(
                            scale: selected ? 1.1 : 1.0,
                            duration: Dt.fast,
                            curve: Dt.curveSpring,
                            child: AnimatedSwitcher(
                              duration: Dt.fast,
                              child: Icon(
                                key: ValueKey(selected),
                                selected ? _icons[i].$1 : _icons[i].$2,
                                size: 24,
                                color: selected ? Dt.pink : Dt.textTertiary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: Dt.fast,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              letterSpacing: selected ? 0.5 : 0.2,
                              color: selected ? Dt.pink : Dt.textTertiary,
                            ),
                            child: Text(_labels[i]),
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
