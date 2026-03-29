import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../features/discover/domain/swipe_result.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: SlideTransition(
          position: _slide,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4E6A), Color(0xFFFF8E53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4E6A).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lottie 心形爆炸背景动画
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Lottie.network(
                      'https://assets5.lottiefiles.com/packages/lf20_ca8aSO.json',
                      fit: BoxFit.cover,
                      repeat: false,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const Text('💕 配对成功！',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        '你和 ${widget.match.partnerName ?? "Ta"} 互相喜欢了',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GlowAvatar(url: widget.myAvatarUrl),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.favorite, color: Colors.white, size: 36),
                          ),
                          _GlowAvatar(url: widget.match.partnerAvatarUrl),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF4E6A),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          widget.onDismiss();
                          if (widget.match.matchId != null) {
                            context.go('/chat/${widget.match.matchId}', extra: {
                              'partnerName': widget.match.partnerName,
                              'partnerAvatarUrl': widget.match.partnerAvatarUrl,
                            });
                          }
                        },
                        child: const Text('立即发消息 💬'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onDismiss,
                        child: const Text('继续滑卡',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowAvatar extends StatelessWidget {
  final String? url;
  const _GlowAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84, height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
        image: url != null && url!.isNotEmpty
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
        color: Colors.white24,
      ),
      child: url == null || url!.isEmpty
          ? const Icon(Icons.person, color: Colors.white, size: 40)
          : null,
    );
  }
}
