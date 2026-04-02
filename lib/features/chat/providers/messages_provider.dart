import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/websocket_service.dart';
import '../data/message_repository.dart';

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier, List<ChatMessage>, String>(
  MessagesNotifier.new,
);

class MessagesNotifier extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  Timer? _pollTimer;
  StreamSubscription? _wsSub;
  StreamSubscription? _readSub;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _refreshing = false;

  bool get hasMore => _hasMore;

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
      // 验证回执属于当前 match
      final receiptMatchId = data['matchId'] as String?;
      if (receiptMatchId != null && receiptMatchId != _matchId) return;
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

    _currentPage = 0;
    _hasMore = true;
    return _fetch(page: 0);
  }

  String get _matchId => arg;

  Future<List<ChatMessage>> _fetch({int page = 0, int size = 20}) async {
    final messages = await ref.read(messageRepositoryProvider).fetchMessages(_matchId, page: page, size: size);
    if (messages.length < size) _hasMore = false;
    return messages;
  }

  /// 上滑加载更多历史消息
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    final current = state.valueOrNull ?? [];
    _currentPage++;
    try {
      final older = await _fetch(page: _currentPage);
      if (older.isEmpty) {
        _hasMore = false;
        return;
      }
      // 去重后追加到末尾（旧消息在后）
      final existingIds = current.map((m) => m.id).toSet();
      final newMsgs = older.where((m) => !existingIds.contains(m.id)).toList();
      state = AsyncData([...current, ...newMsgs]);
    } catch (_) {
      _currentPage--; // 失败回退页码
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _silentRefresh() async {
    if (_refreshing) return;
    if (state is! AsyncData) return;
    _refreshing = true;
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh);
    } catch (_) {
    } finally {
      _refreshing = false;
    }
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
