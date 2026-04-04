import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../domain/notification_item.dart';
import '../providers/notifications_provider.dart';

/// 通知中心页面
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  /// 根据tab筛选通知列表
  List<NotificationItem> _filterNotifications(
    List<NotificationItem> all, int tabIndex,
  ) {
    switch (tabIndex) {
      case 1:
        return all.where((n) => n.type == NotificationType.match).toList();
      case 2:
        return all.where((n) => n.type == NotificationType.message).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    const pink = Color(0xFFFF4D88);

    return Scaffold(
      // backgroundColor从theme获取
      appBar: AppBar(
        // backgroundColor从theme获取
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('通知'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllRead();
              },
              child: const Text(
                '全部已读',
                style: TextStyle(color: pink, fontSize: 14),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: pink,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: pink,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '匹配'),
            Tab(text: '消息'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: List.generate(3, (tabIndex) {
          final filtered = _filterNotifications(notifications, tabIndex);
          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyState(tabIndex),
                      ),
                    ],
                  )
                : AnimationLimiter(
                    child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      indent: 76,
                    ),
                    itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: _NotificationTile(item: filtered[i]),
                        ),
                      ),
                    ),
                  ),
                  ),
          );
        }),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(int tabIndex) {
    final icons = [
      Icons.notifications_none_rounded,
      Icons.favorite_outline_rounded,
      Icons.chat_bubble_outline_rounded,
    ];
    final texts = [
      '暂无新通知',
      '暂无匹配通知',
      '暂无消息通知',
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            child: Icon(
              icons[tabIndex],
              size: 40,
              color: const Color(0xFFFF4D88).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            texts[tabIndex],
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条通知列表项
class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF4D88);

    // 通知图标
    final iconData = item.type == NotificationType.match
        ? Icons.favorite_rounded
        : Icons.chat_bubble_rounded;

    return Container(
      color: item.isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: item.avatarUrl != null
                      ? NetworkImage(item.avatarUrl!)
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: item.avatarUrl == null
                      ? Text(
                          item.senderName.isNotEmpty
                              ? item.senderName[0]
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: pink,
                          ),
                        )
                      : null,
                ),
                // 通知类型小图标
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pink,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(iconData, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // 描述内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 未读红点
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: pink,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 格式化相对时间
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
