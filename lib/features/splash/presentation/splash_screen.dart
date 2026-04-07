import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/token_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/design_tokens.dart';

/// 启动页 — 与 welcome 无缝衔接的沉浸式大图
/// 删 mesh_gradient 流体渐变, 用 welcome 第一张大图作背景
/// 中心: 自绘心形 logo + "春水圈" 大字
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  // 与 welcome 第一张图共用 — 视觉无缝衔接
  static const heroImage =
      'https://images.unsplash.com/photo-1516589091380-5d8e87df6999?w=2048&q=95&fit=crop&auto=format';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _logoScale;

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
      duration: const Duration(milliseconds: 1400),
    );

    // Logo 弹跳进入
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.08), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // 整体淡入
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );

    // 背景图缩放 (Ken Burns 入场)
    _scale = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _start();
  }

  Future<void> _start() async {
    // 预加载下一页大图
    if (mounted) {
      precacheImage(
        const CachedNetworkImageProvider(SplashScreen.heroImage),
        context,
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
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
          // 全屏大图 + Ken Burns 入场缩放
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.scale(
              scale: _scale.value,
              child: child,
            ),
            child: CachedNetworkImage(
              imageUrl: SplashScreen.heroImage,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 600),
              placeholder: (_, __) => const ColoredBox(color: Dt.bgDeep),
              errorWidget: (_, __, ___) => const ColoredBox(color: Dt.bgDeep),
            ),
          ),

          // 三层暗角蒙层 — 让 logo 和文字可读
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80000000),
                    Color(0x55000000),
                    Color(0xCC0A0614),
                    Color(0xFF07080A),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 中部柔和 vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),

          // 心形 Logo 居中偏上
          Align(
            alignment: const Alignment(0, -0.15),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: const _BrandLogo(),
                ),
              ),
            ),
          ),

          // 品牌大字 + 副标题 — 紧贴 logo 下方
          Align(
            alignment: const Alignment(0, 0.18),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '春水圈',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      height: 1.0,
                      shadows: [
                        Shadow(color: Color(0xCC000000), blurRadius: 24),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '遇 见 心 动',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(color: Color(0x99000000), blurRadius: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部加载指示
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 56,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(opacity: _opacity.value * 0.7, child: child),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Dt.pinkLight,
                    strokeWidth: 1.8,
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

/// 品牌Logo — 玫瑰红圆 + 自绘心形 + 多层光晕
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Dt.pinkLight, Dt.pink, Color(0xFFC4304D)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Dt.pink.withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Dt.pink.withValues(alpha: 0.25),
            blurRadius: 80,
            spreadRadius: 12,
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

/// 自绘心形
class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

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
