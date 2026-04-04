import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_item.dart';

/// 本地通知列表Provider（从FCM消息中收集）
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super([]);

  /// 添加一条通知
  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }

  /// 标记全部已读
  void markAllRead() {
    state = state.map((n) => NotificationItem(
      id: n.id,
      type: n.type,
      title: n.title,
      avatarUrl: n.avatarUrl,
      senderName: n.senderName,
      createdAt: n.createdAt,
      isRead: true,
    )).toList();
  }

  /// 清空所有通知
  void clearAll() {
    state = [];
  }
}
