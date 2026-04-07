import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import '../../../shared/theme/design_tokens.dart';

/// 欢迎引导页 — Hinge / Tinder / Bumble 沉浸式风格
/// 全屏大图 + 暗色渐变蒙层 + 大字宣言 + 渐变发光 CTA
/// 主人原则: "我要高级荷尔蒙丰富的风格", "启动页要丰富有层次"
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _current = 0;
  double _pageOffset = 0;  // 滑动浮点 offset, 用于视差
  bool _imagesPreloaded = false;

  // 沉浸式引导 — 顶级 Unsplash 摄影 (1600px 高分辨率, 时尚情侣/人像)
  // 精挑细选: 浪漫氛围 + 高对比度 + 适合暗色 UI
  static const _pages = [
    _WelcomePage(
      // 黄昏夕阳情侣剪影 — 浪漫暖色调
      imageUrl: 'https://images.unsplash.com/photo-1516589091380-5d8e87df6999?w=1600&q=90&fit=crop&auto=format',
      title: '心动\n就在下一次滑动',
      subtitle: '认识此刻在你身边的有趣灵魂',
    ),
    _WelcomePage(
      // 都市夜灯下的女性肖像 — 时尚高级
      imageUrl: 'https://images.unsplash.com/photo-1542596594-649edbc13630?w=1600&q=90&fit=crop&auto=format',
      title: '让心意\n不再沉默',
      subtitle: '文字、语音、礼物 — 用你喜欢的方式靠近',
    ),
    _WelcomePage(
      // 城市夜景情侣 — 蓝紫色调氛围
      imageUrl: 'https://images.unsplash.com/photo-1518621736915-f3b1c41bfd00?w=1600&q=90&fit=crop&auto=format',
      title: '每一次相遇\n都值得安心',
      subtitle: '实名认证 · AI 审核 · 7×24 守护',
    ),
    _WelcomePage(
      // 自然光下的浪漫氛围 — 温暖治愈
      imageUrl: 'https://images.unsplash.com/photo-1474552226712-ac0f0961a954?w=1600&q=90&fit=crop&auto=format',
      title: '春水有意\n知遇心动',
      subtitle: '每一段关系，都值得被温柔以待',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 监听滑动 offset, 用于背景视差
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _pageOffset = _controller.page ?? 0;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 一次性预加载所有 4 张大图, 切换时不会再有空白
    if (!_imagesPreloaded) {
      _imagesPreloaded = true;
      for (final p in _pages) {
        precacheImage(
          CachedNetworkImageProvider(p.imageUrl),
          context,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _pages.length - 1;
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 流体渐变 fallback (图片加载前)
          AnimatedMeshGradient(
            colors: const [
              Color(0xFF1A0A2E),
              Color(0xFF2D1B4E),
              Dt.pink,
              Color(0xFF0A0614),
            ],
            options: AnimatedMeshGradientOptions(
              speed: 2,
              frequency: 2,
              amplitude: 40,
              grain: 0.3,
            ),
          ),

          // 视差背景层 — 在 PageView 之外, 根据 offset 自动平移
          // 让滑动时背景图也跟着滑, 但速度更慢, 创造电影感视差
          Positioned.fill(
            child: Stack(
              children: List.generate(_pages.length, (i) {
                // 计算每张图与当前页的距离
                final delta = (i - _pageOffset).clamp(-1.0, 1.0);
                final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
                if (opacity == 0) return const SizedBox.shrink();
                return Opacity(
                  opacity: opacity,
                  child: _ImmersivePage(
                    page: _pages[i],
                    parallaxOffset: delta,
                  ),
                );
              }),
            ),
          ),

          // 透明手势层 — 接管滑动事件给 _controller
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, __) => const SizedBox.expand(),
          ),

          // 顶部右侧"登录"
          Positioned(
            top: mq.padding.top + 12,
            right: 16,
            child: TextButton(
              onPressed: () => context.go('/auth/login'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: const Text('登录',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  )),
            ),
          ),

          // 底部内容区 — 渐变蒙层 + 标题 + 指示点 + CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(28, 60, 28, mq.padding.bottom + 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xCC000000),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 大标题 — 大字 + 紧 lh + 可换行
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _pages[_current].title,
                      key: ValueKey(_current),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.6,
                        shadows: [
                          Shadow(color: Color(0x99000000), blurRadius: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 副标题
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    child: Text(
                      _pages[_current].subtitle,
                      key: ValueKey('sub_$_current'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15,
                        height: 1.55,
                        letterSpacing: 0.2,
                        shadows: const [
                          Shadow(color: Color(0x66000000), blurRadius: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 指示点
                  Row(
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _current ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: i == _current
                              ? const LinearGradient(
                                  colors: [Dt.pink, Dt.pinkLight],
                                )
                              : null,
                          color: i == _current
                              ? null
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: i == _current
                              ? [
                                  BoxShadow(
                                    color: Dt.pink.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // 主 CTA — 渐变 + 多层光晕，大按钮浮现
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Dt.pink, Dt.pinkLight, Dt.orange],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: [
                          BoxShadow(
                            color: Dt.pink.withValues(alpha: 0.55),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Dt.pink.withValues(alpha: 0.25),
                            blurRadius: 60,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(29),
                          onTap: isLast
                              ? () => context.go('/auth/register')
                              : () => _controller.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
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
                    ),
                  ),

                  if (isLast) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/auth/login'),
                        child: Text.rich(TextSpan(
                          text: '已有账号？',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13),
                          children: const [
                            TextSpan(
                              text: '立即登录',
                              style: TextStyle(
                                color: Dt.pink,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 沉浸式单页 — Ken Burns + 视差平移 + 三层暗角
/// parallaxOffset: -1..1, 来自 PageController, 让背景图随手势平移
class _ImmersivePage extends StatefulWidget {
  final _WelcomePage page;
  final double parallaxOffset;
  const _ImmersivePage({required this.page, this.parallaxOffset = 0});

  @override
  State<_ImmersivePage> createState() => _ImmersivePageState();
}

class _ImmersivePageState extends State<_ImmersivePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _kbCtrl;
  late Animation<double> _scale;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    // Ken Burns: 18 秒缓慢循环, 更柔和不抢戏
    _kbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.05, end: 1.18).animate(
      CurvedAnimation(parent: _kbCtrl, curve: Curves.easeInOutSine),
    );
    _offset = Tween<Offset>(
      begin: const Offset(-0.03, -0.02),
      end: const Offset(0.03, 0.02),
    ).animate(
      CurvedAnimation(parent: _kbCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _kbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // 视差: 滑动时背景按 30% 速度反向平移, 创造"层次感"
    final parallaxX = -widget.parallaxOffset * mq.size.width * 0.3;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ken Burns + 视差大图
        AnimatedBuilder(
          animation: _kbCtrl,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              _offset.value.dx * mq.size.width + parallaxX,
              _offset.value.dy * mq.size.height,
            ),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
          child: CachedNetworkImage(
            imageUrl: widget.page.imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 400),
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

        // 顶部暗角
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 中部 vignette
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.32),
                ],
              ),
            ),
          ),
        ),
      ],
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
