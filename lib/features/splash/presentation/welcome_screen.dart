import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import '../../../shared/theme/design_tokens.dart';

/// 欢迎引导页 — mesh_gradient 流动底层 + 大图融合 + AnimatedSwitcher 切换
/// 主人核心要求: 1) 流动渐变高级感 2) 全屏无黑边 3) 滑动丝滑
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  bool _imagesPreloaded = false;
  late AnimationController _kbCtrl;

  static const _pages = [
    _WelcomePage(
      imageUrl: 'https://images.unsplash.com/photo-1516589091380-5d8e87df6999?w=2048&q=95&fit=crop&auto=format',
      title: '心动\n就在下一次滑动',
      subtitle: '认识此刻在你身边的有趣灵魂',
    ),
    _WelcomePage(
      imageUrl: 'https://images.unsplash.com/photo-1542596594-649edbc13630?w=2048&q=95&fit=crop&auto=format',
      title: '让心意\n不再沉默',
      subtitle: '文字、语音、礼物 — 用你喜欢的方式靠近',
    ),
    _WelcomePage(
      imageUrl: 'https://images.unsplash.com/photo-1518621736915-f3b1c41bfd00?w=2048&q=95&fit=crop&auto=format',
      title: '每一次相遇\n都值得安心',
      subtitle: '实名认证 · AI 审核 · 7×24 守护',
    ),
    _WelcomePage(
      imageUrl: 'https://images.unsplash.com/photo-1474552226712-ac0f0961a954?w=2048&q=95&fit=crop&auto=format',
      title: '春水有意\n知遇心动',
      subtitle: '每一段关系，都值得被温柔以待',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _kbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPreloaded) {
      _imagesPreloaded = true;
      for (final p in _pages) {
        precacheImage(CachedNetworkImageProvider(p.imageUrl), context);
      }
    }
  }

  @override
  void dispose() {
    _kbCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      setState(() => _current++);
    } else {
      context.go('/auth/register');
    }
  }

  void _prev() {
    if (_current > 0) setState(() => _current--);
  }

  void _handleSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -200) {
      _next();
    } else if (v > 200) {
      _prev();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _pages.length - 1;
    final mq = MediaQuery.of(context);
    final isCompact = mq.size.height < 700;

    return Scaffold(
      backgroundColor: Dt.bgDeep,
      body: GestureDetector(
        onHorizontalDragEnd: _handleSwipe,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // L1: mesh_gradient 流体渐变 — 永远在底层流动
              AnimatedMeshGradient(
                colors: const [
                  Color(0xFF14091C),
                  Dt.pink,
                  Color(0xFF0A0614),
                  Color(0xFF3D1A1F),
                ],
                options: AnimatedMeshGradientOptions(
                  speed: 2,
                  frequency: 2,
                  amplitude: 40,
                  grain: 0.25,
                ),
              ),

              // L2: 大图融合层 — Opacity 50% 让流动渐变透出 + AnimatedSwitcher fade 切换
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  child: Opacity(
                    key: ValueKey('img_$_current'),
                    opacity: 0.55,
                    child: _BgImage(url: _pages[_current].imageUrl, kbCtrl: _kbCtrl),
                  ),
                ),
              ),

              // L3: 暗色蒙层
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x80000000),
                          Color(0x33000000),
                          Color(0xCC0A0614),
                          Color(0xFF07080A),
                        ],
                        stops: [0.0, 0.3, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // L4: 中部 vignette
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.1,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // L5: 顶部品牌 + 登录
              Positioned(
                top: mq.padding.top + 14,
                left: 24,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Dt.pinkLight, Dt.pink, Color(0xFFC4304D)],
                          stops: [0.0, 0.6, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Dt.pink.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Text('春水圈',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(color: Color(0x80000000), blurRadius: 8),
                          ],
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1),
                        ),
                        child: const Text('登录',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            )),
                      ),
                    ),
                  ],
                ),
              ),

              // L6: 底部内容区
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      28, 60, 28, mq.padding.bottom + (isCompact ? 20 : 32)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 大字标题 fade + slide
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.18),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _pages[_current].title,
                          key: ValueKey('t_$_current'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 32 : 40,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                            letterSpacing: -0.8,
                            shadows: const [
                              Shadow(color: Color(0xCC000000), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 10 : 14),

                      // 副标题
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim, child: child),
                        child: Text(
                          _pages[_current].subtitle,
                          key: ValueKey('s_$_current'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: isCompact ? 14 : 15,
                            height: 1.55,
                            letterSpacing: 0.2,
                            shadows: const [
                              Shadow(color: Color(0x99000000), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isCompact ? 22 : 32),

                      // 指示点 — 渐变发光
                      Row(
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 340),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _current ? 32 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: i == _current
                                  ? const LinearGradient(
                                      colors: [Dt.pink, Dt.pinkLight, Dt.orange],
                                    )
                                  : null,
                              color: i == _current
                                  ? null
                                  : Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: i == _current
                                  ? [
                                      BoxShadow(
                                        color: Dt.pink.withValues(alpha: 0.6),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: isCompact ? 18 : 24),

                      // 主 CTA — 渐变发光大按钮
                      GestureDetector(
                        onTap: _next,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          height: isCompact ? 54 : 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Dt.pink, Dt.pinkLight, Dt.orange],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(29),
                            boxShadow: [
                              BoxShadow(
                                color: Dt.pink.withValues(alpha: 0.5),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Dt.pink.withValues(alpha: 0.22),
                                blurRadius: 56,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? '开 始 遇 见' : '继 续',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                                if (!isLast) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 20),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (isLast) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/auth/login'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text.rich(TextSpan(
                                text: '已有账号？',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '立即登录',
                                    style: TextStyle(
                                      color: Dt.pinkLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 大图 + Ken Burns 缓慢缩放 (融合在 mesh_gradient 之上)
class _BgImage extends StatelessWidget {
  final String url;
  final AnimationController kbCtrl;
  const _BgImage({required this.url, required this.kbCtrl});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: kbCtrl,
        builder: (_, child) {
          final t = Curves.easeInOutSine.transform(kbCtrl.value);
          final scale = 1.04 + t * 0.10;
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox.expand(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 0),
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage {
  final String imageUrl;
  final String title;
  final String subtitle;

  const _WelcomePage({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });
}
