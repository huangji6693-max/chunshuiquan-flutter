import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

/// Boost 状态 Provider
final boostStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/boost/status');
  return res.data as Map<String, dynamic>;
});

/// 发现页的曝光加速按钮 — 火箭动画
class BoostButton extends ConsumerStatefulWidget {
  const BoostButton({super.key});

  @override
  ConsumerState<BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends ConsumerState<BoostButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _minutesLeft = 0;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPulse() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(boostStatusProvider);

    statusAsync.whenData((data) {
      _active = data['active'] as bool? ?? false;
      _minutesLeft = (data['minutesLeft'] as num?)?.toInt() ?? 0;
      if (_active) {
        _startPulse();
      } else {
        _stopPulse();
      }
    });

    return GestureDetector(
      onTap: _active ? null : _handleBoost,
      child: _AnimBuilder(
        listenable: _pulseController,
        builder: (_, __) {
          final scale = _active ? 1.0 + _pulseController.value * 0.1 : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: (_active
                            ? const Color(0xFF7C4DFF)
                            : const Color(0xFF7C4DFF))
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(
                _active ? Icons.rocket_launch : Icons.bolt_rounded,
                color: const Color(0xFF7C4DFF),
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBoost() async {
    HapticFeedback.heavyImpact();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/boost');
      ref.invalidate(boostStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('曝光加速已激活！30分钟内更多人会看到你'),
              ],
            ),
            backgroundColor: const Color(0xFF7C4DFF),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = (e.response?.data as Map<String, dynamic>?)?['error'] ??
            '激活失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }
}

class _AnimBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const _AnimBuilder(
      {super.key, required super.listenable, required this.builder, this.child});
  @override
  Widget build(BuildContext context) => builder(context, child);
}
