import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/messages_provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/current_user_provider.dart';

final chatProvider = AsyncNotifierProviderFamily<MessagesNotifier, List<dynamic>, String>(
  MessagesNotifier.new,
);

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String? partnerName;
  final String? partnerAvatarUrl;

  const ChatScreen({
    super.key,
    required this.matchId,
    this.partnerName,
    this.partnerAvatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    final myId = ref.read(currentUserProvider).asData?.value.id ?? '';
    try {
      await ref.read(messagesProvider(widget.matchId).notifier)
          .sendMessage(text, myId);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发送失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.matchId));
    final currentUserId = ref.watch(currentUserProvider).asData?.value.id;

    // 消息更新时滚到底部
    ref.listen(messagesProvider(widget.matchId), (_, next) {
      if (next is AsyncData) _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.partnerAvatarUrl != null && widget.partnerAvatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.partnerAvatarUrl!)
                  : null,
              child: widget.partnerAvatarUrl == null || widget.partnerAvatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.partnerName ?? '聊天'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                      child: Text('发送第一条消息吧 👋',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = currentUserId != null && currentUserId == msg.senderId;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('message_input'),
                      controller: _textCtrl,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('send_btn'),
                    onTap: _send,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isMe ? primary : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              message.content as String,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            child: Text(
              _formatTime(message.createdAt as DateTime),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
