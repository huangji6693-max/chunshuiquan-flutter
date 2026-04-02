import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gift_repository.dart';
import '../domain/gift.dart';
import '../../coins/presentation/coin_shop_screen.dart';

/// 礼物列表 Provider
final giftsProvider = FutureProvider<List<Gift>>((ref) {
  return ref.watch(giftRepositoryProvider).getGifts();
});

/// 聊天中的礼物面板 - 底部弹出
class GiftPanel extends ConsumerStatefulWidget {
  final String matchId;
  final VoidCallback? onGiftSent;

  const GiftPanel({
    super.key,
    required this.matchId,
    this.onGiftSent,
  });

  @override
  ConsumerState<GiftPanel> createState() => _GiftPanelState();
}

class _GiftPanelState extends ConsumerState<GiftPanel>
    with SingleTickerProviderStateMixin {
  Gift? _selected;
  bool _sending = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final giftsAsync = ref.watch(giftsProvider);
    final balanceAsync = ref.watch(coinBalanceProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽手柄
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏 + 余额
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  '送TA一份礼物',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // 金币余额
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CoinShopScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700).withOpacity(0.15), Color(0xFFFFA000).withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        balanceAsync.when(
                          data: (c) => Text('$c',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFFE65100))),
                          loading: () => const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5)),
                          error: (_, __) => const Text('--'),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.add_circle,
                            size: 16, color: Colors.orange.shade700),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 礼物列表
          SizedBox(
            height: 130,
            child: giftsAsync.when(
              data: (gifts) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: gifts.length,
                itemBuilder: (context, i) => _buildGiftItem(gifts[i]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('加载失败，请重试')),
            ),
          ),

          // 发送按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _selected != null && !_sending ? _handleSend : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D88),
                  disabledBackgroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: _selected != null ? 3 : 0,
                  shadowColor: const Color(0xFFFF4D88).withOpacity(0.4),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selected != null
                                ? '送出 ${_selected!.name}（${_selected!.coins}金币）'
                                : '选择一个礼物',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildGiftItem(Gift gift) {
    final isSelected = _selected?.id == gift.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = gift);
        _bounceController.forward(from: 0);
      },
      child: _AnimBuilder(
        listenable: _bounceAnim,
        builder: (context, child) {
          final scale =
              isSelected ? _bounceAnim.value : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 90,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF4D88).withOpacity(0.1)
                : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF4D88)
                  : Colors.grey.shade700,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF4D88).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(gift.icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 6),
              Text(
                gift.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFFF4D88)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on,
                      size: 13, color: Colors.amber.shade700),
                  const SizedBox(width: 2),
                  Text(
                    '${gift.coins}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    if (_selected == null) return;
    setState(() => _sending = true);

    try {
      await ref
          .read(giftRepositoryProvider)
          .sendGift(widget.matchId, _selected!.id);

      // 刷新余额
      ref.invalidate(coinBalanceProvider);

      HapticFeedback.heavyImpact();
      widget.onGiftSent?.call();

      if (mounted) {
        Navigator.pop(context, _selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

/// AnimatedBuilder 封装
class _AnimBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
