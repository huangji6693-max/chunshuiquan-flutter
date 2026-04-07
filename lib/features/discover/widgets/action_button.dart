import 'package:flutter/material.dart';
import '../../../shared/theme/design_tokens.dart';

/// 动作按钮 — Dt v4 / Raycast 毛玻璃风格
/// 漂浮在用户照片上, 半透明让照片透出, scale hover (Wise 启发)
class ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              // [v4] 半透明黑替代半透明白 — 与照片融合更深, 不抢戏
              color: const Color(0x33000000),  // 20% 黑
              shape: BoxShape.circle,
              // [v4] 单层细微光晕 — Sentry 启发, 删除装饰 spreadRadius
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.18),
                  blurRadius: 14,
                ),
              ],
              border: Border.all(
                color: Dt.borderMedium,
                width: 1,
              ),
            ),
            child: Icon(widget.icon,
                color: widget.color,
                size: widget.size * 0.46),
          ),
        ),
      ),
    );
  }
}
