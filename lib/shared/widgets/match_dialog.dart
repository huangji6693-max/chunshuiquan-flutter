import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _navigating = false;
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
                colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D88).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.2),
                            radius: 1.1,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                        child: Stack(
                          children: const [
                            _HeartBurst(top: 36, left: 28, size: 20, opacity: 0.18),
                            _HeartBurst(top: 72, right: 36, size: 16, opacity: 0.16),
                            _HeartBurst(bottom: 112, left: 42, size: 18, opacity: 0.14),
                            _HeartBurst(bottom: 68, right: 26, size: 22, opacity: 0.12),
                          ],
                        ),
                      ),
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
                          foregroundColor: const Color(0xFFFF4D88),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _navigating
                            ? null
                            : () {
                                if (widget.match.matchId == null) return;
                                setState(() => _navigating = true);
                                widget.onDismiss();
                                Navigator.of(context).pop();
                                context.go('/chat/${widget.match.matchId}', extra: {
                                  'partnerName': widget.match.partnerName,
                                  'partnerAvatarUrl': widget.match.partnerAvatarUrl,
                                });
                              },
                        child: _navigating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF4D88),
                                ),
                              )
                            : const Text('立即发消息 💬'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _navigating
                            ? null
                            : () {
                                widget.onDismiss();
                                Navigator.of(context).pop();
                              },
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

class _HeartBurst extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final double opacity;

  const _HeartBurst({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Icon(
        Icons.favorite,
        color: Colors.white.withOpacity(opacity),
        size: size,
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
