import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../data/gift_repository.dart';
import '../domain/gift_record.dart';

final receivedGiftsProvider = FutureProvider.autoDispose<List<GiftRecord>>((ref) {
  return ref.watch(giftRepositoryProvider).getReceived();
});

final sentGiftsProvider = FutureProvider.autoDispose<List<GiftRecord>>((ref) {
  return ref.watch(giftRepositoryProvider).getSent();
});

class GiftHistoryScreen extends ConsumerStatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  ConsumerState<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends ConsumerState<GiftHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('礼物记录', style: GoogleFonts.notoSansSc(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurface,
        )),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF4D88),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFF4D88),
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          tabs: const [
            Tab(text: '收到的'),
            Tab(text: '送出的'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GiftList(provider: receivedGiftsProvider, isReceived: true),
          _GiftList(provider: sentGiftsProvider, isReceived: false),
        ],
      ),
    );
  }
}

class _GiftList extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<GiftRecord>> provider;
  final bool isReceived;

  const _GiftList({required this.provider, required this.isReceived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(provider);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        ref.invalidate(provider);
      },
      child: giftsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isReceived
                                ? Icons.card_giftcard
                                : Icons.volunteer_activism,
                            size: 36,
                            color: const Color(0xFFFF4D88),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isReceived ? '还没有收到过礼物' : '还没有送出过礼物',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isReceived ? '让TA送你一个吧 💝' : '送一个表达心意吧 ❤️',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, i) {
              final record = records[i];
              return AnimationConfiguration.staggeredList(
                position: i,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 礼物图标
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(record.giftIcon ?? '🎁',
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // 信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReceived
                                ? '${record.senderName ?? "某人"} 送了你 ${record.giftName ?? "礼物"}'
                                : '你送了 ${record.receiverName ?? "某人"} ${record.giftName ?? "礼物"}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(record.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),

                    // 金币值
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text('${record.giftCoins ?? 0}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                  ),
                ),
              );
            },
          ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4D88))),
        error: (e, _) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(child: Text('网络开小差了', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
