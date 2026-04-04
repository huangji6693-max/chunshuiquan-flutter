import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

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
      iconColors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
      title: '心动\n就在下一次滑动',
      subtitle: '向右滑动，开启一段新故事',
    ),
    _WelcomePage(
      icon: Icons.chat_bubble_rounded,
      iconColors: [Color(0xFF8B5CF6), Color(0xFFFF4D88)],
      title: '让心意\n不再沉默',
      subtitle: '文字、语音、礼物，用你喜欢的方式靠近',
    ),
    _WelcomePage(
      icon: Icons.shield_rounded,
      iconColors: [Color(0xFFFF8A5C), Color(0xFFFF4D88)],
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 流体渐变背景
          AnimatedMeshGradient(
            colors: const [
              Color(0xFF0F0A1A),
              Color(0xFF1A0E2E),
              Color(0xFFFF4D88),
              Color(0xFF0F0A1A),
            ],
            options: AnimatedMeshGradientOptions(
              speed: 1.5,
              frequency: 2,
              amplitude: 30,
              grain: 0.2,
            ),
          ),
          // 暗层让内容更突出
          Container(color: Colors.black.withValues(alpha: 0.4)),

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
                      color: Color(0xFFFF4D88),
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
                                colors: [Color(0xFFFF4D88), Color(0xFF8B5CF6)])
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

                // 主按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D88).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLast
                          ? () => context.go('/auth/register')
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isLast ? '开始遇见' : '继续',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
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
                            color: Color(0xFFFF4D88),
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
            // 图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: page.iconColors),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: page.iconColors.first.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(page.icon, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 48),
            // 大标题
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 18),
            // 副标题
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.5,
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
