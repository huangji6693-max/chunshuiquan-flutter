import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// 语音消息气泡 — 波形动画 + 播放进度
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  bool _playing = false;
  double _progress = 0;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    _positionSub = _player.onPositionChanged.listen((pos) {
      final total = Duration(seconds: widget.durationSeconds);
      if (total.inMilliseconds > 0 && mounted) {
        setState(() => _progress = pos.inMilliseconds / total.inMilliseconds);
      }
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playing = state == PlayerState.playing);
        if (state == PlayerState.completed) {
          setState(() => _progress = 0);
        }
      }
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : const Color(0xFFFF4D88);
    final bgColor = widget.isMe
        ? const Color(0xFFFF4D88)
        : Colors.white;
    final width = 120.0 + widget.durationSeconds * 8.0;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: width.clamp(140.0, 260.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!widget.isMe)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 播放/暂停
            Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: color,
              size: 26,
            ),
            const SizedBox(width: 8),

            // 波形
            Expanded(
              child: _AnimBuilder(
                listenable: _waveCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(double.infinity, 24),
                  painter: _WavePainter(
                    color: color.withOpacity(0.6),
                    activeColor: color,
                    progress: _progress,
                    animValue: _playing ? _waveCtrl.value : 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 时长
            Text(
              '${widget.durationSeconds}"',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final Color activeColor;
  final double progress;
  final double animValue;

  _WavePainter({
    required this.color,
    required this.activeColor,
    required this.progress,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = (size.width / 5).floor();
    final barWidth = 2.5;
    final spacing = (size.width - barCount * barWidth) / (barCount - 1);

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final normalizedI = i / barCount;

      // 随机波形高度（用sin模拟）
      double heightFactor = 0.3 +
          0.7 *
              ((normalizedI * 3.14 * 3).abs() % 1.0) *
              (0.5 + 0.5 * (animValue));
      final barHeight = size.height * heightFactor;
      final y = (size.height - barHeight) / 2;

      final isActive = normalizedI <= progress;
      final paint = Paint()
        ..color = isActive ? activeColor : color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.animValue != animValue;
}

class _AnimBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const _AnimBuilder(
      {super.key, required super.listenable, required this.builder, this.child});
  @override
  Widget build(BuildContext context) => builder(context, child);
}
