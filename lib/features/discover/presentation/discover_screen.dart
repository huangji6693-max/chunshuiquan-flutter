import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/discover_repository.dart';
import '../domain/swipe_result.dart';
import '../../../core/errors/app_exception.dart';
import '../../../features/auth/domain/user_profile.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../shared/widgets/user_card.dart';
import '../../../shared/widgets/match_dialog.dart';
import '../../checkin/presentation/checkin_dialog.dart';
import '../../likes/presentation/likes_screen.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../boost/presentation/boost_button.dart';
import '../../../shared/widgets/animated_empty_state.dart';
import 'package:go_router/go_router.dart';

/// 筛选参数
class DiscoverFilter {
  final int minAge;
  final int maxAge;
  final double maxDistance;
  final String gender; // '' = 所有人, 'male' = 男, 'female' = 女

  const DiscoverFilter({
    this.minAge = 18,
    this.maxAge = 60,
    this.maxDistance = 50,
    this.gender = '',
  });

  DiscoverFilter copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    String? gender,
  }) => DiscoverFilter(
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    maxDistance: maxDistance ?? this.maxDistance,
    gender: gender ?? this.gender,
  );
}

/// Discover 状态管理
class _DiscoverState {
  final List<UserProfile> cards;
  final bool isLoading;
  final SwipeResult? pendingMatch;
  final DiscoverFilter filter;

  const _DiscoverState({
    this.cards = const [],
    this.isLoading = false,
    this.pendingMatch,
    this.filter = const DiscoverFilter(),
  });

  _DiscoverState copyWith({
    List<UserProfile>? cards,
    bool? isLoading,
    SwipeResult? pendingMatch,
    bool clearMatch = false,
    DiscoverFilter? filter,
  }) =>
      _DiscoverState(
        cards: cards ?? this.cards,
        isLoading: isLoading ?? this.isLoading,
        pendingMatch: clearMatch ? null : (pendingMatch ?? this.pendingMatch),
        filter: filter ?? this.filter,
      );
}

class _DiscoverNotifier extends StateNotifier<_DiscoverState> {
  final Ref _ref;
  bool _fetchingMore = false;
  int _swipedCount = 0;
  int _currentPage = 0;
  bool _hasMore = true;

  _DiscoverNotifier(this._ref) : super(const _DiscoverState()) {
    _loadFilterAndFetch();
  }

  /// 从本地存储加载筛选参数，然后拉取数据
  Future<void> _loadFilterAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filter = DiscoverFilter(
        minAge: prefs.getInt('filter_minAge') ?? 18,
        maxAge: prefs.getInt('filter_maxAge') ?? 60,
        maxDistance: prefs.getDouble('filter_maxDistance') ?? 50,
        gender: prefs.getString('filter_gender') ?? '',
      );
      state = state.copyWith(filter: filter);
    } catch (_) {
      // 读取失败使用默认值
    }
    _load();
  }

  /// 保存筛选参数到本地存储
  Future<void> _saveFilter(DiscoverFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('filter_minAge', filter.minAge);
      await prefs.setInt('filter_maxAge', filter.maxAge);
      await prefs.setDouble('filter_maxDistance', filter.maxDistance);
      await prefs.setString('filter_gender', filter.gender);
    } catch (_) {
      // 存储失败静默处理
    }
  }

  /// 应用新的筛选条件
  Future<void> refresh() async {
    _swipedCount = 0;
    _currentPage = 0;
    _hasMore = true;
    state = state.copyWith(cards: []);
    await _load();
  }

  Future<void> applyFilter(DiscoverFilter filter) async {
    await _saveFilter(filter);
    _swipedCount = 0;
    _currentPage = 0;
    _hasMore = true;
    state = state.copyWith(filter: filter, cards: []);
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final f = state.filter;
      final profiles = await _ref.read(discoverRepositoryProvider).fetchFeed(
        minAge: f.minAge,
        maxAge: f.maxAge,
        gender: f.gender.isNotEmpty ? f.gender : null,
        maxDistance: f.maxDistance,
        page: 0,
      );
      if (profiles.length < 20) _hasMore = false;
      state = state.copyWith(cards: profiles, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadMore() async {
    if (_fetchingMore || !_hasMore) return;
    _fetchingMore = true;
    try {
      _currentPage++;
      final f = state.filter;
      final more = await _ref.read(discoverRepositoryProvider).fetchFeed(
        minAge: f.minAge,
        maxAge: f.maxAge,
        gender: f.gender.isNotEmpty ? f.gender : null,
        maxDistance: f.maxDistance,
        page: _currentPage,
      );
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        // 去重
        final existingIds = state.cards.map((c) => c.id).toSet();
        final newCards = more.where((c) => !existingIds.contains(c.id)).toList();
        state = state.copyWith(cards: [...state.cards, ...newCards]);
      }
    } catch (_) {
      _currentPage--; // 失败回退
    } finally {
      _fetchingMore = false;
    }
  }

  Future<void> onSwiped(int cardIndex, String direction) async {
    _swipedCount++;
    final remaining = state.cards.length - _swipedCount;
    if (remaining <= 5) _loadMore();

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

/// 发现页 - Tinder级别UI
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with TickerProviderStateMixin {
  final CardSwiperController _swiperCtrl = CardSwiperController();

  // Super Like 星星overlay动画
  late AnimationController _superLikeAnimCtrl;
  late Animation<double> _superLikeScale;
  late Animation<double> _superLikeOpacity;
  bool _showSuperLikeOverlay = false;
  bool _animatingSuper = false;

  @override
  void initState() {
    super.initState();
    // 异步检查 onboarding 状态（3秒超时，失败不阻塞）
    Future.microtask(() async {
      try {
        final user = await ref.read(currentUserProvider.future)
            .timeout(const Duration(seconds: 3));
        if (!user.onboardingCompleted && mounted) {
          context.go('/onboarding');
        }
      } catch (_) {
        // 超时或网络错误，不阻塞发现页
      }
    });
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
        _animatingSuper = false;
        setState(() => _showSuperLikeOverlay = false);
      }
    });
  }

  void _playSuperLikeAnimation() {
    if (_animatingSuper) return;
    _animatingSuper = true;
    setState(() => _showSuperLikeOverlay = true);
    _superLikeAnimCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _superLikeAnimCtrl.dispose();
    _swiperCtrl.dispose();
    super.dispose();
  }

  /// 判断筛选是否非默认
  bool _isFilterActive(DiscoverFilter filter) {
    return filter.minAge != 18 ||
        filter.maxAge != 60 ||
        filter.maxDistance != 50 ||
        filter.gender.isNotEmpty;
  }

  /// 显示筛选底部弹窗
  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(_discoverNotifierProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        initialFilter: currentFilter,
        onApply: (filter) {
          ref.read(_discoverNotifierProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(_discoverNotifierProvider);
    final notifier = ref.read(_discoverNotifierProvider.notifier);

    // 监听 pendingMatch，弹 MatchDialog
    ref.listen<_DiscoverState>(_discoverNotifierProvider, (prev, next) {
      if (next.pendingMatch != null && prev?.pendingMatch == null) {
        if (!mounted) return;
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
        
        surfaceTintColor: Colors.transparent,
        title: Text(
          '春水圈',
          style: GoogleFonts.notoSansSc(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF4D88),
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        actions: [
          // 签到——带文字标签的胶囊按钮
          GestureDetector(
            onTap: () => CheckInDialog.show(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D88).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF4D88).withValues(alpha: 0.25), width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF4D88), size: 16),
                  SizedBox(width: 4),
                  Text('签到', style: TextStyle(
                    color: Color(0xFFFF4D88), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 谁喜欢我——带数量提示
          GestureDetector(
            onTap: () => Navigator.push(context,
                fadeSlideRoute(const LikesScreen())),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D88).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('喜欢我', style: TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 筛选
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
                  onPressed: () => _showFilterSheet(context, ref),
                  tooltip: '筛选',
                ),
                if (_isFilterActive(discoverState.filter))
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D88),
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D88).withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: discoverState.isLoading && discoverState.cards.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D88)))
          : discoverState.cards.isEmpty
              ? AnimatedEmptyState(
                  icon: Icons.explore_off_rounded,
                  title: '暂时没有更多人了',
                  subtitle: '下拉刷新试试',
                  action: TextButton.icon(
                    onPressed: () => ref.read(_discoverNotifierProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('刷新'),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          CardSwiper(
                            key: const Key('swipe_card'),
                            controller: _swiperCtrl,
                            cardsCount: discoverState.cards.length,
                            numberOfCardsDisplayed: discoverState.cards.length >= 3 ? 3 : discoverState.cards.length,
                            backCardOffset: const Offset(0, -30),
                            scale: 0.95,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onSwipe: (prev, curr, dir) {
                              HapticFeedback.lightImpact();
                              final direction = switch (dir) {
                                CardSwiperDirection.right => 'like',
                                CardSwiperDirection.top => 'superlike',
                                _ => 'nope',
                              };
                              if (direction == 'superlike') {
                                _playSuperLikeAnimation();
                              }
                              notifier.onSwiped(prev, direction);
                              return true;
                            },
                            cardBuilder: (ctx, idx, percentX, percentY) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  UserCard(user: discoverState.cards[idx]),
                                  // 右滑 LIKE overlay
                                  if (percentX > 0)
                                    _SwipeLabel(
                                      text: 'LIKE',
                                      color: const Color(0xFF4CAF50),
                                      opacity: (percentX / 100).clamp(0.0, 1.0),
                                      angle: -0.35,
                                      alignment: Alignment.topLeft,
                                    ),
                                  // 左滑 NOPE overlay
                                  if (percentX < 0)
                                    _SwipeLabel(
                                      text: 'NOPE',
                                      color: const Color(0xFFFF5A5A),
                                      opacity: (-percentX / 100).clamp(0.0, 1.0),
                                      angle: 0.35,
                                      alignment: Alignment.topRight,
                                    ),
                                  // 上滑 SUPER LIKE overlay
                                  if (percentY < 0)
                                    _SwipeLabel(
                                      text: 'SUPER',
                                      color: const Color(0xFF5B9AFF),
                                      opacity: (-percentY / 100).clamp(0.0, 1.0),
                                      angle: 0,
                                      alignment: Alignment.center,
                                      icon: Icons.star_rounded,
                                    ),
                                ],
                              );
                            },
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
                                            .withValues(alpha:0.15),
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

                    // 底部动作按钮 + Boost（避开底部导航栏）
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16,
                          MediaQuery.of(context).padding.bottom + 70),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Boost 曝光加速
                          const BoostButton(),

                          // 不喜欢
                          _ActionButton(
                            icon: Icons.close_rounded,
                            color: const Color(0xFFFF5A5A),
                            label: '不喜欢',
                            size: 62,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _swiperCtrl.swipe(CardSwiperDirection.left);
                            },
                          ),

                          // 超级喜欢按钮 - 蓝色脉冲
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: _SuperLikeBtn(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                _playSuperLikeAnimation();
                                _swiperCtrl.swipe(CardSwiperDirection.top);
                              },
                            ),
                          ),

                          // 喜欢
                          _ActionButton(
                            icon: Icons.favorite_rounded,
                            color: const Color(0xFF4CAF50),
                            label: '喜欢',
                            size: 62,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _swiperCtrl.swipe(CardSwiperDirection.right);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// 滑动标签 overlay
class _SwipeLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double opacity;
  final double angle;
  final Alignment alignment;
  final IconData? icon;

  const _SwipeLabel({
    required this.text,
    required this.color,
    required this.opacity,
    required this.angle,
    required this.alignment,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            alignment: alignment == Alignment.center
                ? Alignment.center
                : alignment == Alignment.topLeft
                    ? const Alignment(-0.7, -0.7)
                    : const Alignment(0.7, -0.7),
            margin: const EdgeInsets.all(20),
            child: Transform.rotate(
              angle: angle,
              child: icon != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 60, color: color),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: color, width: 4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(text,
                              style: TextStyle(
                                color: color,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              )),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(text,
                          style: TextStyle(
                            color: color,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          )),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 动作按钮 - 带阴影和按压效果
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha:0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha:0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: widget.color.withValues(alpha:0.15),
                    width: 2,
                  ),
                ),
                child: Icon(widget.icon,
                    color: widget.color,
                    size: widget.size * 0.44),
              ),
              const SizedBox(height: 6),
              Text(widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Super Like 专用按钮 - 蓝色渐变 + 脉冲动画
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

  static const double _size = 58;
  static const Color _blue = Color(0xFF5B9AFF);
  static const Color _blueLight = Color(0xFF82B4FF);

  @override
  void initState() {
    super.initState();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_blue, _blueLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha:0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _blue.withValues(alpha:0.20),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 6),
              const Text('超级喜欢',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// 筛选底部弹窗
class _FilterBottomSheet extends StatefulWidget {
  final DiscoverFilter initialFilter;
  final ValueChanged<DiscoverFilter> onApply;

  const _FilterBottomSheet({
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late RangeValues _ageRange;
  late double _maxDistance;
  late String _gender;

  static const _genderOptions = [
    {'label': '所有人', 'value': ''},
    {'label': '男', 'value': 'male'},
    {'label': '女', 'value': 'female'},
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.initialFilter.minAge.toDouble(),
      widget.initialFilter.maxAge.toDouble(),
    );
    _maxDistance = widget.initialFilter.maxDistance;
    _gender = widget.initialFilter.gender;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('筛选',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _ageRange = const RangeValues(18, 60);
                    _maxDistance = 50;
                    _gender = '';
                  });
                },
                child: const Text('重置',
                    style: TextStyle(
                        color: Color(0xFFFF4D88),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 年龄范围
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('年龄范围',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              Text('${_ageRange.start.round()} - ${_ageRange.end.round()}岁',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4D88))),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF4D88),
              inactiveTrackColor: const Color(0xFFFF4D88).withValues(alpha:0.25),
              thumbColor: const Color(0xFFFF4D88),
              overlayColor: const Color(0xFFFF4D88).withValues(alpha:0.1),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: _ageRange,
              min: 18,
              max: 60,
              divisions: 42,
              onChanged: (values) => setState(() => _ageRange = values),
            ),
          ),
          const SizedBox(height: 16),

          // 距离范围
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('距离范围',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              Text('${_maxDistance.round()}km',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4D88))),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF4D88),
              inactiveTrackColor: const Color(0xFFFF4D88).withValues(alpha:0.25),
              thumbColor: const Color(0xFFFF4D88),
              overlayColor: const Color(0xFFFF4D88).withValues(alpha:0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _maxDistance,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ),
          const SizedBox(height: 16),

          // 性别筛选
          Text('性别',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _genderOptions.map((option) {
              final selected = _gender == option['value'];
              return ChoiceChip(
                label: Text(option['label']!),
                selected: selected,
                selectedColor: const Color(0xFFFF4D88),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide.none,
                onSelected: (_) => setState(() => _gender = option['value']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // 应用按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D88).withValues(alpha:0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(DiscoverFilter(
                    minAge: _ageRange.start.round(),
                    maxAge: _ageRange.end.round(),
                    maxDistance: _maxDistance,
                    gender: _gender,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                child: const Text('应用筛选',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
