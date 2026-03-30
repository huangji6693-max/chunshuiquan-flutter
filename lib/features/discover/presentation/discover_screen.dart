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
import '../../report/report_bottom_sheet.dart';

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
    if (cardIndex >= state.cards.length) return;

    _swipedCount++;
    final remaining = state.cards.length - _swipedCount;
    if (remaining <= 2) _loadMore();

    if (direction == 'nope') {
      _ref.read(discoverRepositoryProvider).sendSwipe(
          state.cards[cardIndex].id, direction);
      return;
    }
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

  void removeUserById(String userId) {
    state = state.copyWith(
      cards: state.cards.where((card) => card.id != userId).toList(),
    );
  }
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
    final currentCard = discoverState.cards.isNotEmpty ? discoverState.cards.first : null;

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
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            '春水圈',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: Color(0xFF1A1A2E), size: 26),
                  onPressed: currentCard == null
                      ? null
                      : () async {
                          final result = await showReportSheet(
                            context,
                            currentCard.id,
                            currentCard.name,
                          );
                          if ((result == 'reported' || result == 'blocked') &&
                              currentCard.id.isNotEmpty) {
                            notifier.removeUserById(currentCard.id);
                          }
                        },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentCard == null
                          ? Colors.grey.shade300
                          : const Color(0xFFFF4D88),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _ActionBtn(
                            icon: Icons.close_rounded,
                            color: const Color(0xFFFF5A5A),
                            semanticLabel: '不喜欢',
                            size: 68,
                            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.left),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -8),
                            child: _ActionBtn(
                              icon: Icons.star_rounded,
                              color: const Color(0xFF5B9AFF),
                              semanticLabel: '超级喜欢',
                              size: 52,
                              onTap: () => _swiperCtrl.swipe(CardSwiperDirection.top),
                            ),
                          ),
                          _ActionBtn(
                            icon: Icons.favorite_rounded,
                            color: const Color(0xFFFF4D88),
                            semanticLabel: '喜欢',
                            size: 68,
                            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.right),
                          ),
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
  final double size;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: size * 0.44),
        ),
      ),
    );
  }
}
