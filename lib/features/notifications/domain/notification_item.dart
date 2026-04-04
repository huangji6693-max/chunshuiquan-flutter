/// 通知类型
enum NotificationType {
  match,   // 匹配通知
  message, // 消息通知
}

/// 通知数据模型
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;        // 描述文字
  final String? avatarUrl;   // 发送者头像
  final String senderName;   // 发送者名字
  final DateTime createdAt;  // 创建时间
  final bool isRead;         // 是否已读

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    this.avatarUrl,
    required this.senderName,
    required this.createdAt,
    this.isRead = false,
  });
}
