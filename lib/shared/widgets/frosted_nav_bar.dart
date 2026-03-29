import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FrostedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    (Icons.explore, Icons.explore_outlined),
    (Icons.favorite, Icons.favorite_outline),
    (Icons.chat_bubble, Icons.chat_bubble_outline),
    (Icons.person, Icons.person_outline),
  ];

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
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_icons.length, (i) {
                  final selected = i == currentIndex;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: SizedBox(
                      width: 60,
                      height: 56,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selected
                              ? ShaderMask(
                                  key: const ValueKey(true),
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                                  ).createShader(bounds),
                                  child: Icon(
                                    _icons[i].$1,
                                    size: 26,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  key: const ValueKey(false),
                                  _icons[i].$2,
                                  size: 26,
                                  color: Colors.grey.shade400,
                                ),
                        ),
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
