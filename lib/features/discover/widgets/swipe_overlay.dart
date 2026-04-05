import '../../../shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// 滑动 Overlay 标签
/// 已在 DiscoverScreen 中通过 _SwipeLabel 内联实现
/// 此文件保留兼容性
class SwipeOverlay extends StatelessWidget {
  final bool isLike;
  final double opacity;

  const SwipeOverlay({super.key, required this.isLike, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isLike
                ? [Dt.like.withValues(alpha:0.15), Colors.transparent]
                : [Dt.nope.withValues(alpha:0.15), Colors.transparent],
            begin: isLike ? Alignment.centerLeft : Alignment.centerRight,
            end: isLike ? Alignment.centerRight : Alignment.centerLeft,
          ),
          border: Border.all(
            color: isLike ? Dt.like : Dt.nope,
            width: 3,
          ),
        ),
        alignment: isLike ? Alignment.topLeft : Alignment.topRight,
        padding: const EdgeInsets.all(20),
        child: Transform.rotate(
          angle: isLike ? -0.35 : 0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isLike
                    ? Dt.like
                    : Dt.nope,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLike ? 'LIKE' : 'NOPE',
              style: TextStyle(
                color: isLike
                    ? Dt.like
                    : Dt.nope,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
