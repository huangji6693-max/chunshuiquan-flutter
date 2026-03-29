import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/messages_provider.dart';
import '../../../core/providers/current_user_provider.dart';
import '../data/message_repository.dart';

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

  List<types.Message> _toUiMessages(
      List<ChatMessage> messages, String myId, String? partnerName, String? partnerAvatar) {
    return messages.map((m) {
      final isMe = m.senderId == myId;
      return types.TextMessage(
        id: m.id,
        text: m.content,
        createdAt: m.createdAt.millisecondsSinceEpoch,
        author: types.User(
          id: m.senderId,
          firstName: isMe ? null : (partnerName ?? 'Ta'),
          imageUrl: isMe ? null : partnerAvatar,
        ),
      );
    }).toList()
      ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
  }

  Future<void> _handleSend(types.PartialText msg) async {
    final myId = ref.read(currentUserProvider).asData?.value.id ?? '';
    try {
      await ref.read(messagesProvider(widget.matchId).notifier)
          .sendMessage(msg.text, myId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('发送失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.matchId));
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final myId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.partnerAvatarUrl != null &&
                      widget.partnerAvatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.partnerAvatarUrl!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: widget.partnerAvatarUrl == null ||
                      widget.partnerAvatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName ?? '聊天',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const Text('在线',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              // TODO: Agora 语音通话
            },
          ),
        ],
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (messages) => Chat(
          messages: _toUiMessages(
              messages, myId, widget.partnerName, widget.partnerAvatarUrl),
          onSendPressed: _handleSend,
          user: types.User(id: myId),
          showUserAvatars: true,
          showUserNames: false,
          theme: DefaultChatTheme(
            primaryColor: const Color(0xFFFF4D88),
            secondaryColor: const Color(0xFFF8F8F8),
            backgroundColor: Colors.white,
            inputBackgroundColor: const Color(0xFFF5F5F5),
            inputBorderRadius: BorderRadius.circular(26),
            messageBorderRadius: 20,
            inputTextColor: Colors.black87,
            inputTextStyle: const TextStyle(fontSize: 15),
            inputPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            sentMessageBodyTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
            receivedMessageBodyTextStyle: const TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 15,
              height: 1.4,
            ),
            dateDividerTextStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            sendButtonIcon: const Icon(
              Icons.send_rounded,
              color: Color(0xFFFF4D88),
            ),
            sendingIcon: const Icon(
              Icons.access_time,
              size: 12,
              color: Colors.white54,
            ),
            emptyChatPlaceholderTextStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
          ),
          emptyState: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 64, color: Color(0xFFFFCDD2)),
                const SizedBox(height: 16),
                Text(
                  '跟 ${widget.partnerName ?? "Ta"} 说声 Hi 吧 👋',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          ),
          avatarBuilder: (author) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: author.imageUrl != null
                  ? CachedNetworkImageProvider(author.imageUrl!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: author.imageUrl == null
                  ? Text(
                      (author.firstName ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
