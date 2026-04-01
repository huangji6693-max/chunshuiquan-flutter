import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/network/websocket_service.dart';
import '../data/message_repository.dart';

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier, List<ChatMessage>, String>(
  MessagesNotifier.new,
);

class MessagesNotifier extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  Timer? _pollTimer;
  StreamSubscription? _wsSub;
  StreamSubscription? _readSub;

  @override
  Future<List<ChatMessage>> build(String arg) async {
    // 15秒轮询兜底（WebSocket 优先）
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _silentRefresh());

    // WebSocket 新消息到达时立即刷新
    final ws = ref.read(webSocketServiceProvider);
    _wsSub = ws.onMessage.listen((_) => _silentRefresh());

    // WebSocket 已读回执：更新本地消息状态
    _readSub = ws.onReadReceipt.listen((data) {
      final current = state.valueOrNull;
      if (current == null) return;
      final readerId = data['readerId'] as String?;
      if (readerId == null) return;
      // 标记该读者发送的消息为已读
      state = AsyncData(current.map((m) {
        if (m.senderId != readerId && !m.isRead) {
          return ChatMessage(
            id: m.id,
            content: m.content,
            senderId: m.senderId,
            createdAt: m.createdAt,
            isRead: true,
          );
        }
        return m;
      }).toList());
    });

    ref.onDispose(() {
      _pollTimer?.cancel();
      _wsSub?.cancel();
      _readSub?.cancel();
    });

    return _fetch();
  }

  String get _matchId => arg;

  Future<List<ChatMessage>> _fetch() {
    return ref.read(messageRepositoryProvider).fetchMessages(_matchId);
  }

  Future<void> _silentRefresh() async {
    if (state is! AsyncData) return;
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh);
    } catch (_) {}
  }

  /// 乐观更新：立即显示，失败回滚
  Future<void> sendMessage(String content, String myUserId) async {
    final current = state.valueOrNull ?? [];

    final optimistic = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderId: myUserId,
      createdAt: DateTime.now(),
      isRead: false,
    );

    state = AsyncData([optimistic, ...current]);

    try {
      final sent = await ref.read(messageRepositoryProvider).sendMessage(_matchId, content);
      final updated = state.valueOrNull ?? [];
      state = AsyncData(
        updated.map((m) => m.id == optimistic.id ? sent : m).toList(),
      );
    } catch (e) {
      final updated = state.valueOrNull ?? [];
      state = AsyncData(updated.where((m) => m.id != optimistic.id).toList());
      rethrow;
    }
  }
}
