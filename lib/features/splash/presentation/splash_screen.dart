import '../../../shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/token_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 启动页 — Dt v4 / Lambo + Sanity 风格
/// 哲学：UI消失，人闪耀。删除流体渐变装饰，改为纯黑 + 单色径向光晕。
/// "春水圈"作为宣言时刻 (Lambo 0.92 lh)。
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
      backgroundColor: Dt.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // [v4] 单一径向光晕 — Sanity 启发，替代流体渐变装饰
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Dt.pink.withValues(alpha: 0.18),
                    Dt.bgDeep,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Logo 居中 (上 1/3 位置, 更接近 Lambo hero 节奏)
          Align(
            alignment: const Alignment(0, -0.25),
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

          // [v4] 品牌宣言时刻 — displayHero 0.96 lh -1.8 ls
          Align(
            alignment: const Alignment(0, 0.35),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '春水圈',
                    style: TextStyle(
                      color: Dt.textPrimary,
                      fontSize: 56,
                      fontWeight: FontWeight.w600,
                      height: 0.96,
                      letterSpacing: -1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '遇 见 心 动',
                    style: TextStyle(
                      color: Dt.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // [v4] 底部 1px 边界进度环, 隐式表达"加载中" (Vercel 影子即边框)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(opacity: _opacity.value * 0.6, child: child),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Dt.pink,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 品牌Logo — Dt v4 极简版
/// Lambo 启发: 单色 + 单层细微光晕, 删除 3 色径向 + 多层装饰
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Dt.pink,
        boxShadow: [
          BoxShadow(
            color: Dt.pink.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(42, 38),
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
