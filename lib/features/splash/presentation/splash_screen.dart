import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import '../../../core/storage/token_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 启动页 — 对标 Tinder：巨大品牌Logo + 流体渐变 + 极简
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      final token = await ref.read(tokenManagerProvider).getAccessToken();
      if (!mounted) return;
      context.go(token != null && token.isNotEmpty ? '/discover' : '/welcome');
    } catch (_) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 流体渐变背景
          AnimatedMeshGradient(
            colors: const [
              Color(0xFF1A0A2E),
              Color(0xFFFF4D88),
              Color(0xFF0A0614),
              Color(0xFF7C3AED),
            ],
            options: AnimatedMeshGradientOptions(
              speed: 3,
              frequency: 2,
              amplitude: 50,
              grain: 0.35,
            ),
          ),

          // 暗层
          Container(color: Colors.black.withValues(alpha: 0.3)),

          // Logo居中
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: const _BrandLogo(),
                ),
              ),
            ),
          ),

          // 底部品牌文字
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(
                opacity: _opacity.value,
                child: child,
              ),
              child: const Column(
                children: [
                  Text(
                    '春水圈',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '遇见心动',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 品牌Logo——自定义绘制水滴形心形
/// 不依赖Material Icons，有独特辨识度
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFF6B9D),
            Color(0xFFFF4D88),
            Color(0xFFE8366D),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D88).withValues(alpha: 0.5),
            blurRadius: 60,
            spreadRadius: 20,
          ),
          BoxShadow(
            color: const Color(0xFFFF4D88).withValues(alpha: 0.2),
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(52, 48),
          painter: _HeartPainter(),
        ),
      ),
    );
  }
}

/// 自绘心形——比Material Icons更饱满更有品牌感
class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // 饱满心形路径
    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.15, h * 0.55, -w * 0.05, h * 0.25, w * 0.25, h * 0.08);
    path.cubicTo(w * 0.35, h * 0.0, w * 0.45, h * 0.05, w * 0.5, h * 0.2);
    path.cubicTo(w * 0.55, h * 0.05, w * 0.65, h * 0.0, w * 0.75, h * 0.08);
    path.cubicTo(w * 1.05, h * 0.25, w * 0.85, h * 0.55, w * 0.5, h * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
