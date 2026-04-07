import 'package:flutter/material.dart';
import '../../../shared/theme/design_tokens.dart';

/// Super Like 专用按钮 - 蓝色渐变 + 脉冲动画
class SuperLikeBtn extends StatefulWidget {
  final VoidCallback onTap;
  const SuperLikeBtn({super.key, required this.onTap});

  @override
  State<SuperLikeBtn> createState() => _SuperLikeBtnState();
}

class _SuperLikeBtnState extends State<SuperLikeBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const double _size = 44;
  static const Color _blue = Dt.superLike;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '超级喜欢',
      button: true,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // [v4] 与 ActionButton 统一: 半透明黑 + 单层细微光晕
              color: const Color(0x33000000),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.18),
                  blurRadius: 14,
                ),
              ],
              border: Border.all(color: Dt.borderMedium, width: 1),
            ),
            child: const Icon(Icons.star_rounded,
                color: _blue, size: 22),
          ),
        ),
      ),
    );
  }
}
