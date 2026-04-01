import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checkin_repository.dart';

final checkInStatusProvider = FutureProvider<CheckInStatus>((ref) {
  return ref.watch(checkInRepositoryProvider).getStatus();
});

/// 每日签到弹窗 — 顶级UI
class CheckInDialog extends ConsumerStatefulWidget {
  const CheckInDialog({super.key});

  @override
  ConsumerState<CheckInDialog> createState() => _CheckInDialogState();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CheckInDialog(),
    );
  }
}

class _CheckInDialogState extends ConsumerState<CheckInDialog>
    with SingleTickerProviderStateMixin {
  bool _checking = false;
  bool _justCheckedIn = false;
  int _reward = 0;
  late AnimationController _coinController;
  late Animation<double> _coinBounce;

  static const _dayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static const _rewards = [10, 15, 20, 25, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _coinBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -30), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -30, end: 0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0, end: -15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -15, end: 0), weight: 25),
    ]).animate(CurvedAnimation(parent: _coinController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(checkInStatusProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D88).withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: statusAsync.when(
          data: (status) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                children: [
                  const Text('每日签到',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (status.streakDays > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '连续${status.streakDays}天',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // 7天签到状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final checked = status.weekStatus[i];
                  final isToday = i == DateTime.now().weekday - 1;

                  return Column(
                    children: [
                      // 天数标签
                      Text('周${_dayLabels[i]}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),

                      // 签到圆圈
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: checked
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF4D88),
                                    Color(0xFFFF8A5C)
                                  ],
                                )
                              : null,
                          color: checked ? null : Colors.grey.shade100,
                          border: isToday && !checked
                              ? Border.all(
                                  color: const Color(0xFFFF4D88), width: 2)
                              : null,
                          boxShadow: checked
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF4D88)
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: checked
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : Text(
                                  '+${_rewards[i]}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isToday
                                        ? const Color(0xFFFF4D88)
                                        : Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 签到成功动画 or 签到按钮
              if (_justCheckedIn) ...[
                _AnimBuilder(
                  listenable: _coinBounce,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _coinBounce.value),
                    child: Column(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: Colors.amber, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          '+$_reward 金币',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF4D88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D88),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('又是元气满满的一天！',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: status.checkedInToday || _checking
                        ? null
                        : _handleCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D88),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: status.checkedInToday ? 0 : 4,
                      shadowColor:
                          const Color(0xFFFF4D88).withOpacity(0.4),
                    ),
                    child: _checking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            status.checkedInToday
                                ? '今天已签到 ✓'
                                : '签到领${status.todayReward}金币',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ],
          ),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(
            height: 100,
            child: Center(child: Text('加载失败，请稍后再试')),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    setState(() => _checking = true);
    try {
      final result =
          await ref.read(checkInRepositoryProvider).checkIn();
      HapticFeedback.heavyImpact();
      setState(() {
        _justCheckedIn = true;
        _reward = result.todayReward;
      });
      _coinController.forward();
      ref.invalidate(checkInStatusProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
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
