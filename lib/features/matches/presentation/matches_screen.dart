import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../data/match_repository.dart';
import '../../../core/services/heartbeat_service.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../shared/theme/design_tokens.dart';

final matchesProvider = FutureProvider.autoDispose<List<MatchItem>>((ref) {
  return ref.watch(matchRepositoryProvider).fetchMatches();
});

/// 匹配页 - 升级版UI
/// 顶部新匹配区域 + 消息列表 + 下拉刷新
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesProvider);
    return Scaffold(
      
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 品牌 Logo — 与 discover/splash 一致的发光浮现
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Dt.pinkLight, Dt.pink, Color(0xFFE8366D)],
                  stops: [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Dt.pink.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 14),
            const Text('匹配',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  height: 1.0,
                  color: Dt.textPrimary,
                )),
          ],
        ),
      ),
      body: state.when(
        loading: () => const MatchesSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text('请检查网络后重试', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => ref.invalidate(matchesProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return _EmptyState();
          }

          final newMatches = matches.where((m) => m.isNew == true).toList();
          final conversations = matches.where((m) => m.isNew != true).toList()
            // 按 lastMessageAt 排序，有消息的在前，最新的在前
            ..sort((a, b) {
              final aTime = a.lastMessageAt;
              final bTime = b.lastMessageAt;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async => ref.invalidate(matchesProvider),
            child: CustomScrollView(
              slivers: [
                // [v4] 新匹配区域 — Sanity 极简 eyebrow 标题
                if (newMatches.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: _SectionEyebrow(label: 'NEW MATCHES'),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: newMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (_, i) => _NewMatchAvatar(match: newMatches[i]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ] else ...[
                  const SliverToBoxAdapter(
                    child: _SectionEyebrow(label: 'NEW MATCHES'),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Text('去发现页多滑滑，好事即将发生',
                          style: TextStyle(
                              color: Dt.textTertiary,
                              fontSize: 14,
                              letterSpacing: 0.1)),
                    ),
                  ),
                ],

                // [v4] 消息列表标题 — eyebrow 风格
                const SliverToBoxAdapter(
                  child: _SectionEyebrow(label: 'MESSAGES'),
                ),

                // 消息列表 + staggered 动画
                if (conversations.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: _ConversationTile(match: conversations[i]),
                          ),
                        ),
                      ),
                      childCount: conversations.length,
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('快去发送第一条消息吧 👋',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                      ),
                    ),
                  ),

                // 底部padding防Tab bar遮挡
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Dt.pink.withValues(alpha:0.1),
                  Dt.orange.withValues(alpha:0.1),
                ],
              ),
            ),
            child: const Icon(Icons.favorite_outline,
                size: 48, color: Dt.pink),
          ),
          const SizedBox(height: 20),
          Text('还没有匹配',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('去滑卡认识新朋友吧',
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// 新匹配头像 - 渐变光环
class _NewMatchAvatar extends StatelessWidget {
  final MatchItem match;
  const _NewMatchAvatar({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/chat/${match.matchId}', extra: {
        'partnerName': match.otherName,
        'partnerAvatarUrl': match.otherAvatarUrl,
      }),
      child: Column(
        children: [
          // 渐变光环头像（粉→橙）+ 多层柔和发光
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: Dt.gradientAccent,
              boxShadow: [
                BoxShadow(
                  color: Dt.pink.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Dt.orange.withValues(alpha: 0.25),
                  blurRadius: 36,
                  spreadRadius: 3,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Dt.bgDeep,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: match.otherAvatarUrl != null
                    ? ResizeImage(
                        CachedNetworkImageProvider(match.otherAvatarUrl!),
                        width: 200,
                      )
                    : null,
                backgroundColor: Dt.bgElevated,
                child: match.otherAvatarUrl == null
                    ? Text(
                        match.otherName.isNotEmpty
                            ? match.otherName[0]
                            : '?',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Dt.pink),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(
              match.otherName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// 消息列表项 - 精致设计
class _ConversationTile extends ConsumerWidget {
  final MatchItem match;
  const _ConversationTile({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 尝试获取在线状态
    final onlineState = ref.watch(onlineStatusProvider(match.otherId));
    final isOnline = onlineState.valueOrNull ?? false;

    // 格式化时间：优先显示 lastMessageAt，否则显示 createdAt
    final displayTime = match.lastMessageAt ?? match.createdAt;
    final timeStr = _formatTime(displayTime);

    // 消息预览文本——图片消息显示📷，礼物显示🎁
    var previewText = (match.lastMessage?.isNotEmpty == true)
        ? match.lastMessage!
        : '还没聊过，打个招呼？';
    if (previewText.startsWith('[图片]')) previewText = '📷 图片';
    if (previewText.contains('送了你') || previewText.contains('礼物')) previewText = '🎁 $previewText';
    final hasUnread = match.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        splashColor: Dt.pink.withValues(alpha: 0.06),
        highlightColor: Dt.pink.withValues(alpha: 0.03),
        borderRadius: Dt.rLg,
        onTap: () => context.go('/chat/${match.matchId}', extra: {
          'partnerName': match.otherName,
          'partnerAvatarUrl': match.otherAvatarUrl,
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // 头像 + 在线绿点 + Hero过渡
              Stack(
                children: [
                  Hero(
                    tag: 'avatar_${match.matchId}',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: match.otherAvatarUrl != null
                          ? ResizeImage(
                              CachedNetworkImageProvider(match.otherAvatarUrl!),
                              width: 200,
                            )
                          : null,
                      backgroundColor: Dt.bgElevated,
                      child: match.otherAvatarUrl == null
                          ? Text(
                              match.otherName.isNotEmpty
                                  ? match.otherName[0]
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Dt.pink),
                            )
                          : null,
                    ),
                  ),
                  // 在线绿点 (平面风格，无发光阴影)
                  if (isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Dt.online,
                          border: Border.all(color: Dt.bgPrimary, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // 名字 + 消息预览
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(match.otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: -0.1,
                                  color: Dt.textPrimary)),
                        ),
                        if (match.otherVipTier != null && match.otherVipTier != 'none') ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified,
                              size: 16,
                              color: match.otherVipTier == 'diamond'
                                  ? const Color(0xFFE040FB)
                                  : Dt.vipGold),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: hasUnread
                              ? Dt.textPrimary
                              : Dt.textSecondary,
                          fontSize: 14,
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          height: 1.3),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 时间 + 未读气泡
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr,
                      style: TextStyle(
                          color: hasUnread
                              ? Dt.pink
                              : Dt.textTertiary,
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal)),
                  const SizedBox(height: 6),
                  // 未读数实心气泡 (无渐变/无阴影)
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Dt.pink,
                        borderRadius: Dt.rPill,
                      ),
                      child: Text(
                        match.unreadCount > 99
                            ? '99+'
                            : '${match.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
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

  /// 格式化时间显示（相对时间）
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    // 判断是否是昨天
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return '昨天';
    }
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('MM/dd').format(dt);
  }
}

/// [v4] Section eyebrow 标题 — Sanity / Composio 风格
/// 大写 + 字距 + 短横线 + 极小尺寸 = 编辑感
class _SectionEyebrow extends StatelessWidget {
  final String label;
  const _SectionEyebrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 1,
            color: Dt.pink,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Dt.pink,
                letterSpacing: 1.2,
              )),
        ],
      ),
    );
  }
}
