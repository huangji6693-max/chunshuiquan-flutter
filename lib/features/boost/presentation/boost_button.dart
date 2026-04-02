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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _active
                    ? const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)])
                    : const LinearGradient(
                        colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)]),
                boxShadow: [
                  BoxShadow(
                    color: (_active
                            ? const Color(0xFF7C4DFF)
                            : const Color(0xFFFF4D88))
                        .withValues(alpha:0.4),
                    blurRadius: _active ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _active ? Icons.rocket_launch : Icons.flash_on,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (_active)
                    Text('${_minutesLeft}m',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Text(_active ? '加速中' : '加速',
                  style: TextStyle(
                    color: _active ? const Color(0xFF7C4DFF) : const Color(0xFFFF4D88),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
              ],
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
