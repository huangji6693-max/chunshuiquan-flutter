import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../data/discover_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../features/auth/domain/user_profile.dart';
import '../../../shared/widgets/user_card.dart';

final discoverProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(discoverRepositoryProvider).fetchFeed();
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final CardSwiperController _swiperCtrl = CardSwiperController();

  @override
  void dispose() {
    _swiperCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSwipe(int idx, CardSwiperDirection dir, List<UserProfile> cards) async {
    if (idx >= cards.length) return;
    final user = cards[idx];
    final direction = dir == CardSwiperDirection.right ? 'like'
        : dir == CardSwiperDirection.left ? 'nope'
        : dir == CardSwiperDirection.top ? 'superlike'
        : 'nope';
    try {
      await ref.read(discoverRepositoryProvider).sendSwipe(user.id, direction);
      if (direction == 'like' || direction == 'superlike') {
        // TODO: 检查是否 match，显示 match 动画
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('春水圈', style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        )),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (cards) => cards.isEmpty
            ? const Center(child: Text('暂时没有更多人了\n明天再来看看 👀',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)))
            : Column(
                children: [
                  Expanded(
                    child: CardSwiper(
                      key: const Key('swipe_card'),
                      controller: _swiperCtrl,
                      cardsCount: cards.length,
                      onSwipe: (prev, curr, dir) {
                        _onSwipe(prev, dir, cards);
                        return true;
                      },
                      cardBuilder: (ctx, idx, _, __) => UserCard(user: cards[idx]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionBtn(Icons.close, Colors.red, () => _swiperCtrl.swipe(CardSwiperDirection.left)),
                        _ActionBtn(Icons.star, Colors.amber, () => _swiperCtrl.swipe(CardSwiperDirection.top)),
                        _ActionBtn(Icons.favorite, Colors.pink, () => _swiperCtrl.swipe(CardSwiperDirection.right)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
