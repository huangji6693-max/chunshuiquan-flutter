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
              color: Colors.white.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            child: const Icon(Icons.star_rounded,
                color: _blue, size: 22),
          ),
        ),
      ),
    );
  }
}
