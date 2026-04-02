import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import '../../../core/storage/token_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 启动页 — 流体网格渐变 + 品牌Logo弹性动画
/// 参考 Soul/探探 的沉浸式启动体验
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Logo 弹性动画
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.03), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)),
    );

    // 文字动画
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(_fadeCtrl);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _fadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      final token = await ref.read(tokenManagerProvider).getAccessToken();
      if (!mounted) return;
      context.go(token != null && token.isNotEmpty ? '/discover' : '/welcome');
    } catch (e) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 流体网格渐变背景——核心视觉
          AnimatedMeshGradient(
            colors: const [
              Color(0xFF1A0E2E), // 深紫
              Color(0xFFFF4D88), // 品牌粉
              Color(0xFF0F0A1A), // 深黑
              Color(0xFF8B5CF6), // 紫色
            ],
            options: AnimatedMeshGradientOptions(
              speed: 2,
              frequency: 3,
              amplitude: 40,
              grain: 0.3,
            ),
          ),

          // 半透明暗层——让Logo更突出
          Container(
            color: Colors.black.withValues(alpha:0.25),
          ),

          // 主内容
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo 心形
                AnimatedBuilder(
                  listenable: _logoCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.2),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D88).withValues(alpha:0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 品牌名
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        const Text('春水圈',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                            )),
                        const SizedBox(height: 12),
                        Text('遇见心动的 Ta',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const AnimatedBuilder({
    super.key, required super.listenable, required this.builder, this.child,
  });
  @override
  Widget build(BuildContext context) => builder(context, child);
}
