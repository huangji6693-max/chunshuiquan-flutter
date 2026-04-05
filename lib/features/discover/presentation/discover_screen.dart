import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../providers/discover_provider.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../shared/widgets/user_card.dart';
import '../../../shared/widgets/match_dialog.dart';
import '../../checkin/presentation/checkin_dialog.dart';
import '../../boost/presentation/boost_button.dart';
import '../../../shared/widgets/animated_empty_state.dart';
import 'package:go_router/go_router.dart';
import '../widgets/action_button.dart';
import '../widgets/super_like_btn.dart';
import '../widgets/swipe_label.dart';
import '../widgets/filter_sheet.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/theme/design_tokens.dart';

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
    final currentFilter = ref.read(discoverNotifierProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        initialFilter: currentFilter,
        onApply: (filter) {
          ref.read(discoverNotifierProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverNotifierProvider);
    final notifier = ref.read(discoverNotifierProvider.notifier);

    // 监听 pendingMatch，弹 MatchDialog
    ref.listen<DiscoverState>(discoverNotifierProvider, (prev, next) {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 品牌Logo——自绘心形，和启动页一致
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Dt.pinkLight, Dt.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Dt.pink.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(16, 15),
                  painter: MiniHeartPainter(),
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // 签到——极简圆形图标
          IconButton(
            onPressed: () => CheckInDialog.show(context),
            icon: Icon(Icons.redeem_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
            tooltip: '签到',
          ),
          // 喜欢我
          IconButton(
            onPressed: () => context.push('/likes'),
            icon: const Icon(Icons.people_alt_rounded,
                color: Dt.pink, size: 22),
            tooltip: '谁喜欢我',
          ),
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
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Dt.pink,
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
              child: CircularProgressIndicator(color: Dt.pink))
          : discoverState.cards.isEmpty
              ? AnimatedEmptyState(
                  icon: Icons.explore_rounded,
                  title: '暂时看完了',
                  subtitle: '扩大距离或调整筛选条件',
                  action: TextButton.icon(
                    onPressed: () => ref.read(discoverNotifierProvider.notifier).refresh(),
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
                                    SwipeLabel(
                                      text: 'LIKE',
                                      color: Dt.like,
                                      opacity: (percentX / 100).clamp(0.0, 1.0),
                                      angle: -0.35,
                                      alignment: Alignment.topLeft,
                                    ),
                                  // 左滑 NOPE overlay
                                  if (percentX < 0)
                                    SwipeLabel(
                                      text: 'NOPE',
                                      color: Dt.nope,
                                      opacity: (-percentX / 100).clamp(0.0, 1.0),
                                      angle: 0.35,
                                      alignment: Alignment.topRight,
                                    ),
                                  // 上滑 SUPER LIKE overlay
                                  if (percentY < 0)
                                    SwipeLabel(
                                      text: 'SUPER',
                                      color: Dt.superLike,
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
                                        color: Dt.superLike
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        size: 100,
                                        color: Dt.superLike,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 底部动作按钮 - Tinder风格：小-大-小-大 节奏
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24,
                          MediaQuery.of(context).padding.bottom + 70),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Boost 小按钮 44px 紫色
                          const BoostButton(),
                          const SizedBox(width: 16),

                          // NOPE 大按钮 56px 红色
                          ActionButton(
                            icon: Icons.close_rounded,
                            color: Dt.nope,
                            size: 56,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _swiperCtrl.swipe(CardSwiperDirection.left);
                            },
                          ),
                          const SizedBox(width: 16),

                          // SuperLike 小按钮 44px 蓝色
                          SuperLikeBtn(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _playSuperLikeAnimation();
                              _swiperCtrl.swipe(CardSwiperDirection.top);
                            },
                          ),
                          const SizedBox(width: 16),

                          // LIKE 大按钮 56px 绿色
                          ActionButton(
                            icon: Icons.favorite_rounded,
                            color: Dt.like,
                            size: 56,
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
