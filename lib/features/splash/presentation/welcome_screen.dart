import '../../../shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// [v4] mesh_gradient 装饰删除 (Lambo 哲学: 装饰即廉价)

/// 欢迎引导页 — 暗色沉浸式，荷尔蒙风格
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _current = 0;

  static const _pages = [
    _WelcomePage(
      icon: Icons.local_fire_department_rounded,
      iconColors: [Dt.pink, Dt.pinkLight],
      title: '心动\n就在下一次滑动',
      subtitle: '向右滑动，开启一段新故事',
    ),
    _WelcomePage(
      icon: Icons.chat_bubble_rounded,
      iconColors: [Color(0xFF8B5CF6), Dt.pink],
      title: '让心意\n不再沉默',
      subtitle: '文字、语音、礼物，用你喜欢的方式靠近',
    ),
    _WelcomePage(
      icon: Icons.shield_rounded,
      iconColors: [Dt.orange, Dt.pink],
      title: '每一次相遇\n都值得安心',
      subtitle: '实名认证 · AI审核 · 7×24守护',
    ),
  ];

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
      backgroundColor: Dt.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // [v4] 单色径向光晕替代流体渐变 (Sanity 启发)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.0,
                colors: [Color(0x26FF4D88), Dt.bgDeep],
                stops: [0.0, 0.65],
              ),
            ),
          ),

          // 页面内容
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),

          // 右上角登录入口（每页都显示）
          Positioned(
            top: mq.padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('登录',
                  style: TextStyle(
                      color: Dt.pink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ),

          // 底部操作区
          Positioned(
            left: 28,
            right: 28,
            bottom: mq.padding.bottom + 40,
            child: Column(
              children: [
                // 指示点
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _current ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: i == _current
                            ? const LinearGradient(
                                colors: [Dt.pink, Color(0xFF8B5CF6)])
                            : null,
                        color: i == _current
                            ? null
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // [v4] 主按钮 — Sanity/Uber 极简纯色 pill, 删渐变装饰
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLast
                        ? () => context.go('/auth/register')
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Dt.pink,
                      foregroundColor: Colors.white,
                      shadowColor: Dt.pink.withValues(alpha: 0.3),
                      elevation: 6,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      isLast ? '开始遇见' : '继续',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),

                if (isLast) ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: Text.rich(TextSpan(
                      text: '已有账号？',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      children: const [
                        TextSpan(
                          text: '立即登录',
                          style: TextStyle(
                            color: Dt.pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )),
                  ),
                ] else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_WelcomePage page) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          children: [
            const Spacer(flex: 3),
            // [v4] 图标 — 单色 + 单层细微光晕, 删渐变装饰
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: page.iconColors.first,
                borderRadius: Dt.rXl,
                boxShadow: [
                  BoxShadow(
                    color: page.iconColors.first.withValues(alpha: 0.22),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Icon(page.icon, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 56),
            // [v4] 大标题 — Lambo 紧 lh + 负字距
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Dt.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w600,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 20),
            // [v4] 副标题 — Linear 暖灰
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Dt.textSecondary,
                fontSize: 16,
                height: 1.55,
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage {
  final IconData icon;
  final List<Color> iconColors;
  final String title;
  final String subtitle;

  const _WelcomePage({
    required this.icon,
    required this.iconColors,
    required this.title,
    required this.subtitle,
  });
}
