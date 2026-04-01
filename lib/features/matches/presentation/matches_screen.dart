import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../data/match_repository.dart';
import '../../../core/services/heartbeat_service.dart';
import '../../../shared/widgets/skeleton_loading.dart';

final matchesProvider = FutureProvider<List<MatchItem>>((ref) {
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
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('匹配',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1)),
      ),
      body: state.when(
        loading: () => const MatchesSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('网络开小差了', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(matchesProvider),
                child: const Text('重试',
                    style: TextStyle(color: Color(0xFFFF4D88))),
              ),
            ],
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
            color: const Color(0xFFFF4D88),
            onRefresh: () async => ref.invalidate(matchesProvider),
            child: CustomScrollView(
              slivers: [
                // 新匹配区域
                if (newMatches.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
                        ).createShader(bounds),
                        child: const Text('新匹配',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: newMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => _NewMatchAvatar(match: newMatches[i]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),
                ] else ...[
                  // 空匹配占位
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
                        ).createShader(bounds),
                        child: const Text('新匹配',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1)),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Center(
                        child: Text('缘分正在路上，继续发现吧 💫',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),
                ],

                // 消息列表标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('消息',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            letterSpacing: 1)),
                  ),
                ),

                // 消息列表
                if (conversations.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ConversationTile(match: conversations[i]),
                      childCount: conversations.length,
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('快去发送第一条消息吧 👋',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                  const Color(0xFFFF4D88).withOpacity(0.1),
                  const Color(0xFFFF8A5C).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(Icons.favorite_outline,
                size: 48, color: Color(0xFFFF4D88)),
          ),
          const SizedBox(height: 20),
          const Text('还没有匹配',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('去滑卡认识新朋友吧',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
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
          // 渐变光环头像（粉→橙）
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D88).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: match.otherAvatarUrl != null
                    ? CachedNetworkImageProvider(match.otherAvatarUrl!)
                    : null,
                backgroundColor: const Color(0xFFF5F5F5),
                child: match.otherAvatarUrl == null
                    ? Text(
                        match.otherName.isNotEmpty
                            ? match.otherName[0]
                            : '?',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF4D88)),
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
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
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

    // 消息预览文本
    final previewText = match.lastMessage ?? '还没聊过，打个招呼？';
    final hasUnread = match.unreadCount > 0;

    return InkWell(
      onTap: () => context.go('/chat/${match.matchId}', extra: {
        'partnerName': match.otherName,
        'partnerAvatarUrl': match.otherAvatarUrl,
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 头像 + 在线绿点
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: match.otherAvatarUrl != null
                      ? CachedNetworkImageProvider(match.otherAvatarUrl!)
                      : null,
                  backgroundColor: const Color(0xFFF5F5F5),
                  child: match.otherAvatarUrl == null
                      ? Text(
                          match.otherName.isNotEmpty
                              ? match.otherName[0]
                              : '?',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF4D88)),
                        )
                      : null,
                ),
                // 在线绿点
                if (isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4CAF50),
                        border: Border.all(color: Colors.white, width: 2.5),
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
                  Text(match.otherName,
                      style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: hasUnread
                            ? Colors.white
                            : Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        height: 1.3),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 时间 + 未读气泡 + 通话按钮
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeStr,
                    style: TextStyle(
                        color: hasUnread
                            ? const Color(0xFFFF4D88)
                            : Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 未读数红色气泡
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D88),
                          borderRadius: BorderRadius.circular(10),
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
                    GestureDetector(
                      onTap: () => context.push('/call/${match.matchId}', extra: {
                        'partnerName': match.otherName,
                        'partnerAvatarUrl': match.otherAvatarUrl,
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D88).withOpacity(0.1),
                        ),
                        child: const Icon(Icons.call,
                            color: Color(0xFFFF4D88), size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
