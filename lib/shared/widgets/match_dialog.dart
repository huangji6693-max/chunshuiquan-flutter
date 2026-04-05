import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../features/discover/domain/swipe_result.dart';
import '../theme/design_tokens.dart';

/// 匹配成功弹窗 - 升级版
/// 深色半透明背景 + 星星粒子效果 + 双方头像从两侧飞入 + 爱心弹跳
class MatchDialog extends StatefulWidget {
  final SwipeResult match;
  final String myAvatarUrl;
  final VoidCallback onDismiss;

  const MatchDialog({
    super.key,
    required this.match,
    required this.myAvatarUrl,
    required this.onDismiss,
  });

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog>
    with TickerProviderStateMixin {
  // 主入场动画控制器
  late final AnimationController _mainCtrl;
  // 左头像飞入动画
  late final Animation<Offset> _leftSlide;
  // 右头像飞入动画
  late final Animation<Offset> _rightSlide;
  // 头像透明度
  late final Animation<double> _avatarFade;
  // 爱心缩放弹跳
  late final Animation<double> _heartScale;
  // 文字和按钮入场
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  // 星星粒子动画控制器
  late final AnimationController _starsCtrl;

  @override
  void initState() {
    super.initState();

    // 主动画控制器（1.2秒）
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 左头像从左侧飞入（0~0.5）
    _leftSlide = Tween<Offset>(
      begin: const Offset(-3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // 右头像从右侧飞入（0.1~0.55）
    _rightSlide = Tween<Offset>(
      begin: const Offset(3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.1, 0.55, curve: Curves.easeOutBack),
    ));

    // 头像透明度
    _avatarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 爱心弹跳缩放（0.4~0.7）
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    ));

    // 文字和按钮淡入+上滑（0.6~1.0）
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    ));

    // 星星粒子循环动画
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _mainCtrl.forward();

    // 震动反馈
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 深色半透明背景
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(color: Colors.black.withValues(alpha:0.7)),
          ),

          // 星星粒子效果
          AnimatedBuilder(
            animation: _starsCtrl,
            builder: (_, __) => CustomPaint(
              size: screenSize,
              painter: _StarsPainter(
                progress: _starsCtrl.value,
              ),
            ),
          ),

          // 主内容
          AnimatedBuilder(
            animation: _mainCtrl,
            builder: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 双方头像 + 爱心
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 左侧头像（我的）
                        SlideTransition(
                          position: _leftSlide,
                          child: FadeTransition(
                            opacity: _avatarFade,
                            child: _AnimatedAvatar(url: widget.myAvatarUrl),
                          ),
                        ),

                        // 中间爱心
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Transform.scale(
                            scale: _heartScale.value,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Dt.pink, Color(0xFFFF7043)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Dt.pink.withValues(alpha:0.5),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),

                        // 右侧头像（对方）
                        SlideTransition(
                          position: _rightSlide,
                          child: FadeTransition(
                            opacity: _avatarFade,
                            child: _AnimatedAvatar(url: widget.match.partnerAvatarUrl),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 文字和按钮
                    SlideTransition(
                      position: _contentSlide,
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: Column(
                          children: [
                            // 主文字
                            const Text(
                              '心动了！💕',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '你和 ${widget.match.partnerName ?? "Ta"} 配对成功了',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha:0.7),
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // 发消息按钮（粉红渐变）
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: const LinearGradient(
                                  colors: [Dt.pink, Color(0xFFFF7043)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Dt.pink.withValues(alpha:0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onDismiss();
                                  if (widget.match.matchId != null) {
                                    context.go('/chat/${widget.match.matchId}', extra: {
                                      'partnerName': widget.match.partnerName,
                                      'partnerAvatarUrl': widget.match.partnerAvatarUrl,
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: const Text(
                                  '发消息',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 继续滑动按钮（白色边框）
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: widget.onDismiss,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: const Text(
                                  '继续滑动',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  }
}

/// 头像组件 - 带光晕效果
class _AnimatedAvatar extends StatelessWidget {
  final String? url;
  const _AnimatedAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Dt.pink.withValues(alpha:0.4),
            blurRadius: 20,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha:0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        image: url?.isNotEmpty == true
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
        color: Colors.white24,
      ),
      child: url?.isNotEmpty != true
          ? const Icon(Icons.person, color: Colors.white, size: 44)
          : null,
    );
  }
}

/// 星星粒子画笔 - 用CustomPainter画随机闪烁的小星星
class _StarsPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42); // 固定种子，保证星星位置一致

  _StarsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const starCount = 50;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < starCount; i++) {
      // 用固定种子生成位置
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final baseRadius = _random.nextDouble() * 2 + 0.5;

      // 每颗星星有不同的闪烁频率和相位
      final phase = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 2 + 1;
      final twinkle = (sin(progress * speed * 2 * pi + phase) + 1) / 2;

      final opacity = twinkle * 0.8 + 0.1;
      final radius = baseRadius * (twinkle * 0.5 + 0.5);

      paint.color = Color.lerp(
        Colors.white,
        const Dt.pink,
        _random.nextDouble() * 0.3,
      )!.withValues(alpha:opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);

      // 部分星星画十字光芒
      if (baseRadius > 1.5 && twinkle > 0.6) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha:opacity * 0.4)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

        final glowLen = radius * 3;
        canvas.drawLine(
          Offset(x - glowLen, y),
          Offset(x + glowLen, y),
          glowPaint,
        );
        canvas.drawLine(
          Offset(x, y - glowLen),
          Offset(x, y + glowLen),
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
