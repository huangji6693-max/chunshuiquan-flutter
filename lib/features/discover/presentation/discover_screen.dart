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

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with TickerProviderStateMixin {
  final CardSwiperController _swiperCtrl = CardSwiperController();

  // Super Like 星星overlay动画控制器
  late AnimationController _superLikeAnimCtrl;
  late Animation<double> _superLikeScale;
  late Animation<double> _superLikeOpacity;
  bool _showSuperLikeOverlay = false;

  @override
  void initState() {
    super.initState();
    _superLikeAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _superLikeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _superLikeAnimCtrl,
      curve: Curves.easeOut,
    ));
    _superLikeOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_superLikeAnimCtrl);

    _superLikeAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showSuperLikeOverlay = false);
      }
    });
  }

  /// 触发Super Like星星overlay动画
  void _playSuperLikeAnimation() {
    setState(() => _showSuperLikeOverlay = true);
    _superLikeAnimCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _superLikeAnimCtrl.dispose();
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
                  icon: const Icon(Icons.tune_rounded,
                      color: Color(0xFF1A1A2E), size: 26),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4D88),
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
                      child: Stack(
                        children: [
                          CardSwiper(
                            key: const Key('swipe_card'),
                            controller: _swiperCtrl,
                            cardsCount: discoverState.cards.length,
                            onSwipe: (prev, curr, dir) {
                              final direction = switch (dir) {
                                CardSwiperDirection.right => 'like',
                                CardSwiperDirection.top => 'superlike',
                                _ => 'nope',
                              };
                              // 向上滑动触发Super Like动画
                              if (direction == 'superlike') {
                                _playSuperLikeAnimation();
                              }
                              notifier.onSwiped(prev, direction);
                              return true;
                            },
                            cardBuilder: (ctx, idx, _, __) =>
                                UserCard(user: discoverState.cards[idx]),
                          ),
                          // Super Like 蓝色星星 overlay 动画
                          if (_showSuperLikeOverlay)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _superLikeAnimCtrl,
                                  builder: (context, child) => Opacity(
                                    opacity: _superLikeOpacity.value,
                                    child: Transform.scale(
                                      scale: _superLikeScale.value,
                                      child: child,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5B9AFF)
                                            .withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        size: 100,
                                        color: Color(0xFF5B9AFF),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                            child: _SuperLikeBtn(
                              onTap: () {
                                _playSuperLikeAnimation();
                                _swiperCtrl.swipe(CardSwiperDirection.top);
                              },
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

/// Super Like 专用按钮，带蓝色渐变边框和脉冲动画
class _SuperLikeBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _SuperLikeBtn({required this.onTap});

  @override
  State<_SuperLikeBtn> createState() => _SuperLikeBtnState();
}

class _SuperLikeBtnState extends State<_SuperLikeBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const double _size = 56;
  static const Color _blue = Color(0xFF5B9AFF);
  static const Color _blueLight = Color(0xFF82B4FF);

  @override
  void initState() {
    super.initState();
    // 持续脉冲动画，吸引用户注意
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '超级喜欢',
      button: true,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 蓝色渐变背景
              gradient: const LinearGradient(
                colors: [_blue, _blueLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _blue.withOpacity(0.20),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.star_rounded,
                color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
