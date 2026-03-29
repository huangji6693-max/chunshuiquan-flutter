import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../data/discover_repository.dart';
import '../domain/swipe_result.dart';
import '../../../core/errors/app_exception.dart';
import '../../../features/auth/domain/user_profile.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../shared/widgets/user_card.dart';
import '../../../shared/widgets/match_dialog.dart';

// DiscoverState 包含卡片列表 + 待弹出的 match
class _DiscoverState {
  final List<UserProfile> cards;
  final bool isLoading;
  final SwipeResult? pendingMatch;

  const _DiscoverState({
    this.cards = const [],
    this.isLoading = false,
    this.pendingMatch,
  });

  _DiscoverState copyWith({
    List<UserProfile>? cards,
    bool? isLoading,
    SwipeResult? pendingMatch,
    bool clearMatch = false,
  }) =>
      _DiscoverState(
        cards: cards ?? this.cards,
        isLoading: isLoading ?? this.isLoading,
        pendingMatch: clearMatch ? null : (pendingMatch ?? this.pendingMatch),
      );
}

class _DiscoverNotifier extends StateNotifier<_DiscoverState> {
  final Ref _ref;
  bool _fetchingMore = false;
  int _swipedCount = 0;

  _DiscoverNotifier(this._ref) : super(const _DiscoverState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final profiles = await _ref.read(discoverRepositoryProvider).fetchFeed();
      state = state.copyWith(cards: profiles, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadMore() async {
    if (_fetchingMore) return;
    _fetchingMore = true;
    try {
      final more = await _ref.read(discoverRepositoryProvider).fetchFeed();
      if (more.isNotEmpty) {
        state = state.copyWith(cards: [...state.cards, ...more]);
      }
    } finally {
      _fetchingMore = false;
    }
  }

  Future<void> onSwiped(int cardIndex, String direction) async {
    _swipedCount++;
    final remaining = state.cards.length - _swipedCount;
    if (remaining <= 2) _loadMore();

    if (direction == 'nope') {
      if (cardIndex < state.cards.length) {
        _ref.read(discoverRepositoryProvider).sendSwipe(
            state.cards[cardIndex].id, direction);
      }
      return;
    }

    if (cardIndex >= state.cards.length) return;
    try {
      final result = await _ref
          .read(discoverRepositoryProvider)
          .sendSwipe(state.cards[cardIndex].id, direction);
      if (result.matched) {
        state = state.copyWith(pendingMatch: result);
      }
    } on AppException {
      // 静默处理，卡片已滑走
    }
  }

  void dismissMatch() => state = state.copyWith(clearMatch: true);
}

final _discoverNotifierProvider =
    StateNotifierProvider<_DiscoverNotifier, _DiscoverState>(
  (ref) => _DiscoverNotifier(ref),
);

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

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(_discoverNotifierProvider);
    final notifier = ref.read(_discoverNotifierProvider.notifier);

    // 监听 pendingMatch，弹 MatchDialog
    ref.listen<_DiscoverState>(_discoverNotifierProvider, (prev, next) {
      if (next.pendingMatch != null && prev?.pendingMatch == null) {
        final myAvatar = ref
                .read(currentUserProvider)
                .asData
                ?.value
                .firstAvatar ??
            '';
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => MatchDialog(
            match: next.pendingMatch!,
            myAvatarUrl: myAvatar,
            onDismiss: notifier.dismissMatch,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('春水圈',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            )),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
        ],
      ),
      body: discoverState.isLoading && discoverState.cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : discoverState.cards.isEmpty
              ? const Center(
                  child: Text('暂时没有更多人了\n明天再来看看 👀',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey)))
              : Column(
                  children: [
                    Expanded(
                      child: CardSwiper(
                        key: const Key('swipe_card'),
                        controller: _swiperCtrl,
                        cardsCount: discoverState.cards.length,
                        onSwipe: (prev, curr, dir) {
                          final direction = switch (dir) {
                            CardSwiperDirection.right => 'like',
                            CardSwiperDirection.top => 'superlike',
                            _ => 'nope',
                          };
                          notifier.onSwiped(prev, direction);
                          return true;
                        },
                        cardBuilder: (ctx, idx, _, __) =>
                            UserCard(user: discoverState.cards[idx]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionBtn(Icons.close, Colors.red, '不喜欢',
                              () => _swiperCtrl.swipe(CardSwiperDirection.left)),
                          _ActionBtn(Icons.star, Colors.amber, '超级喜欢',
                              () => _swiperCtrl.swipe(CardSwiperDirection.top)),
                          _ActionBtn(Icons.favorite, Colors.pink, '喜欢',
                              () => _swiperCtrl.swipe(CardSwiperDirection.right)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.semanticLabel, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))],
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}
