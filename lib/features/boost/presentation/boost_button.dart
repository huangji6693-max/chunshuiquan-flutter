import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/boost_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/design_tokens.dart';

/// Boost 状态 Provider
final boostStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(boostRepositoryProvider).getStatus();
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
                // [v4] 与 ActionButton/SuperLikeBtn 统一: 半透明黑 + 单层光晕
                color: const Color(0x33000000),
                boxShadow: [
                  BoxShadow(
                    color: Dt.boost.withValues(alpha: 0.18),
                    blurRadius: 14,
                  ),
                ],
                border: Border.all(color: Dt.borderMedium, width: 1),
              ),
              child: Icon(
                _active ? Icons.rocket_launch : Icons.bolt_rounded,
                color: Dt.boost,
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
      await ref.read(boostRepositoryProvider).activate();
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
            backgroundColor: Dt.boost,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is AppException ? e.message : '激活失败';
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
