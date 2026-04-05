import '../../../shared/theme/design_tokens.dart';
import 'dart:math';
import 'package:flutter/material.dart';

/// 礼物飘屏动画 — 送礼物成功后的全屏特效
/// 使用方式: GiftAnimationOverlay.show(context, '🌹', '玫瑰')
class GiftAnimationOverlay {
  static void show(BuildContext context, String icon, String name) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GiftAnimationWidget(
        icon: icon,
        name: name,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _GiftAnimationWidget extends StatefulWidget {
  final String icon;
  final String name;
  final VoidCallback onDone;

  const _GiftAnimationWidget({
    required this.icon,
    required this.name,
    required this.onDone,
  });

  @override
  State<_GiftAnimationWidget> createState() => _GiftAnimationWidgetState();
}

class _GiftAnimationWidgetState extends State<_GiftAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    // 生成粒子
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 100 + _random.nextDouble() * 200,
        size: 4 + _random.nextDouble() * 8,
        color: [
          Dt.pink,
          Dt.orange,
          Colors.amber,
          Colors.pink.shade200,
          Colors.white,
        ][_random.nextInt(5)],
      ));
    }

    // 主动画：大礼物图标缩放进出
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_mainController);

    // 粒子动画
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _mainController.forward();
    _particleController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return _AnimBuilder(
      listenable: _mainController,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              // 半透明背景
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3 * _opacityAnim.value),
                ),
              ),

              // 粒子层
              _AnimBuilder(
                listenable: _particleController,
                builder: (context, _) {
                  return CustomPaint(
                    size: mq.size,
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                      center: Offset(
                        mq.size.width / 2,
                        mq.size.height / 2,
                      ),
                    ),
                  );
                },
              ),

              // 中心礼物
              Center(
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Opacity(
                    opacity: _opacityAnim.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.icon,
                            style: const TextStyle(fontSize: 80)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Dt.pink.withValues(alpha: 0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Dt.pink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Offset center;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final distance = p.speed * progress;
      final x = center.dx + cos(p.angle) * distance;
      final y = center.dy + sin(p.angle) * distance;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}

/// AnimatedBuilder 封装（如果已在其他文件定义则可移除）
class _AnimBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
