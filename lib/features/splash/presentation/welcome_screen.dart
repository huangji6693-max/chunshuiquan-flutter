import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 欢迎引导页 — 首次安装时展示，3页滑动引导
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
      emoji: '💖',
      title: '心动，就在下一次滑动',
      subtitle: '向右滑动，开启一段新故事\n每一次心动都值得被认真对待',
      gradientColors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
    ),
    _WelcomePage(
      emoji: '💬',
      title: '让心意不再沉默',
      subtitle: '匹配成功的那一刻，你们的故事就开始了\n文字、语音、礼物，用你喜欢的方式靠近',
      gradientColors: [Color(0xFFFF6B8A), Color(0xFFFF8A5C)],
    ),
    _WelcomePage(
      emoji: '🛡️',
      title: '每一次相遇都安心',
      subtitle: '实名认证 · AI照片审核 · 7×24小时守护\n你只管心动，安全交给我们',
      gradientColors: [Color(0xFFFF8A5C), Color(0xFFFFB74D)],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 页面
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),

          // 底部操作区
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 32,
            child: Column(
              children: [
                // 指示点
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _current ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _current
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 按钮
                if (_current == _pages.length - 1) ...[
                  // 最后一页：注册 + 登录
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.go('/auth/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF4D88),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.black26,
                      ),
                      child: const Text('注册新账号',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => context.go('/auth/login'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('已有账号，登录',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  // 非最后一页：下一步 + 跳过
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF4D88),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.black26,
                      ),
                      child: const Text('下一步',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: Text('跳过',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_WelcomePage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Emoji 大图
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(page.emoji,
                      style: const TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 40),
              Text(page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  )),
              const SizedBox(height: 16),
              Text(page.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.6,
                  )),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _WelcomePage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });
}
