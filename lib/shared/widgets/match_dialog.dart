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
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
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
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4E6A), Color(0xFFFF8E53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💕 配对成功！',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '你和 ${widget.match.partnerName ?? "Ta"} 互相喜欢了',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Avatar(url: widget.myAvatarUrl),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.favorite, color: Colors.white, size: 32),
                    ),
                    _Avatar(url: widget.match.partnerAvatarUrl),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF4E6A),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    widget.onDismiss();
                    if (widget.match.matchId != null) {
                      context.go(
                        '/chat/${widget.match.matchId}',
                        extra: {
                          'partnerName': widget.match.partnerName,
                          'partnerAvatarUrl': widget.match.partnerAvatarUrl,
                        },
                      );
                    }
                  },
                  child: const Text('立即发消息'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text('继续滑卡', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
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
