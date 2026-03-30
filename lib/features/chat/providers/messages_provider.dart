import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/message_repository.dart';

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier, List<ChatMessage>, String>(
  MessagesNotifier.new,
);

class MessagesNotifier extends FamilyAsyncNotifier<List<ChatMessage>, String>
    with WidgetsBindingObserver {
  Timer? _pollTimer;

  @override
  Future<List<ChatMessage>> build(String arg) async {
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _pollTimer?.cancel();
    });
    return _fetch();
  }

  String get _matchId => arg;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _silentRefresh(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _silentRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopPolling();
    }
  }

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

    // 临时消息（本地 ID）
    final optimistic = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderId: myUserId,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 最新在前（与后端 DESC 排序一致）
    state = AsyncData([optimistic, ...current]);

    try {
      final sent = await ref.read(messageRepositoryProvider).sendMessage(_matchId, content);
      final updated = state.valueOrNull ?? [];
      // 轮询可能在 API 返回前刷新了 state，导致 optimistic 消息消失
      // 若 optimistic 还在 → 替换；若已被轮询覆盖 → 插到最前（去重）
      if (updated.any((m) => m.id == optimistic.id)) {
        state = AsyncData(updated.map((m) => m.id == optimistic.id ? sent : m).toList());
      } else {
        final withoutDup = updated.where((m) => m.id != sent.id).toList();
        state = AsyncData([sent, ...withoutDup]);
      }
    } catch (e) {
      // 回滚：仅在 optimistic 仍存在时删除
      final updated = state.valueOrNull ?? [];
      state = AsyncData(updated.where((m) => m.id != optimistic.id).toList());
      rethrow;
    }
  }
}
