import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../call/presentation/voice_call_screen.dart';
import '../../gifts/presentation/gift_panel.dart';
import '../../gifts/presentation/gift_animation_overlay.dart';
import '../providers/messages_provider.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/services/heartbeat_service.dart';
import '../../../core/network/websocket_service.dart';
import '../../profile/data/upload_repository.dart';
import '../data/message_repository.dart';

/// 聊天页 - 升级版UI
/// 精致AppBar + 自定义气泡颜色 + 图片发送 + 在线状态
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
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    // 尝试订阅 WebSocket 频道
    try {
      ref.read(webSocketServiceProvider).subscribeChatChannel(widget.matchId);
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      // 不读ref在dispose中，WebSocket取消订阅在上层处理
    } catch (_) {}
    super.dispose();
  }

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
        // 已读状态通过metadata传递
        metadata: {'isRead': m.isRead},
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

  /// 选择图片并上传，发送图片URL作为消息
  Future<void> _handleImageSend() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      // 上传到 Cloudinary
      final url = await ref.read(uploadRepositoryProvider)
          .uploadImage(File(picked.path));
      // 发送图片URL作为消息内容
      final myId = ref.read(currentUserProvider).asData?.value.id ?? '';
      await ref.read(messagesProvider(widget.matchId).notifier)
          .sendMessage('[图片] $url', myId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('图片发送失败')));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  /// 弹出礼物面板
  void _showGiftPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GiftPanel(
        matchId: widget.matchId,
        onGiftSent: () {},
      ),
    ).then((gift) {
      // gift 是选中的 Gift 对象，送出成功后返回
      if (gift != null && mounted) {
        GiftAnimationOverlay.show(context, gift.icon, gift.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.matchId));
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final myId = currentUser?.id ?? '';

    // 获取对方在线状态（需要对方userId，这里从消息中推断）
    // TODO: 后端在match数据中返回otherId后可直接使用

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        size: 20, color: Color(0xFF1A1A2E)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // 对方头像
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: widget.partnerAvatarUrl != null &&
                            widget.partnerAvatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.partnerAvatarUrl!)
                        : null,
                    backgroundColor: const Color(0xFFF5F5F5),
                    child: widget.partnerAvatarUrl == null ||
                            widget.partnerAvatarUrl!.isEmpty
                        ? const Icon(Icons.person,
                            size: 22, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // 名字 + 在线状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.partnerName ?? '聊天',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('在线',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 语音通话按钮
                  IconButton(
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D88).withOpacity(0.1),
                      ),
                      child: const Icon(Icons.call_outlined,
                          color: Color(0xFFFF4D88), size: 20),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoiceCallScreen(
                          matchId: widget.matchId,
                          partnerName: widget.partnerName ?? '对方',
                          partnerAvatarUrl: widget.partnerAvatarUrl,
                        ),
                      ),
                    ),
                  ),

                  // 视频通话按钮（预留）
                  IconButton(
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D88).withOpacity(0.1),
                      ),
                      child: const Icon(Icons.videocam_outlined,
                          color: Color(0xFFFF4D88), size: 20),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('视频通话功能即将上线')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: messagesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4D88))),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (messages) => Chat(
          messages: _toUiMessages(
              messages, myId, widget.partnerName, widget.partnerAvatarUrl),
          onSendPressed: _handleSend,
          user: types.User(id: myId),
          showUserAvatars: true,
          showUserNames: false,
          theme: DefaultChatTheme(
            // 自己的消息：粉红渐变色（通过primaryColor实现）
            primaryColor: const Color(0xFFFF4D88),
            // 对方的消息：白色气泡
            secondaryColor: Colors.white,
            backgroundColor: const Color(0xFFF8F5F5),
            inputBackgroundColor: Colors.white,
            inputBorderRadius: BorderRadius.circular(28),
            messageBorderRadius: 20,
            inputTextColor: const Color(0xFF1A1A2E),
            inputTextStyle: const TextStyle(fontSize: 15),
            inputPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            inputContainerDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
              fontWeight: FontWeight.w500,
            ),
            sendButtonIcon: const Icon(
              Icons.send_rounded,
              color: Color(0xFFFF4D88),
              size: 24,
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
            receivedMessageDocumentIconColor: const Color(0xFFFF4D88),
            sentMessageDocumentIconColor: Colors.white,
          ),
          emptyState: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF4D88).withOpacity(0.1),
                        const Color(0xFFFF8A5C).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      size: 36, color: Color(0xFFFF4D88)),
                ),
                const SizedBox(height: 16),
                Text(
                  '跟 ${widget.partnerName ?? "Ta"} 说声 Hi 吧',
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text('开始你们的对话',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
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
              backgroundColor: const Color(0xFFF5F5F5),
              child: author.imageUrl == null
                  ? Text(
                      (author.firstName ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF4D88)),
                    )
                  : null,
            ),
          ),
          // 自定义输入框底部：礼物 + 图片 + 输入框 + 发送
          customBottomWidget: _ChatInput(
            onSend: (text) => _handleSend(types.PartialText(text: text)),
            onImageTap: _handleImageSend,
            onGiftTap: () => _showGiftPanel(context),
            uploading: _uploadingImage,
          ),
        ),
      ),
    );
  }
}

/// 自定义聊天输入框
/// 左侧图片按钮 + 圆角输入框 + 粉红色发送按钮
class _ChatInput extends StatefulWidget {
  final void Function(String) onSend;
  final VoidCallback onImageTap;
  final VoidCallback onGiftTap;
  final bool uploading;

  const _ChatInput({
    required this.onSend,
    required this.onImageTap,
    required this.onGiftTap,
    required this.uploading,
  });

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 礼物按钮
          GestureDetector(
            onTap: widget.onGiftTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF4D88).withOpacity(0.15),
                    const Color(0xFFFF8A5C).withOpacity(0.15),
                  ],
                ),
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: Color(0xFFFF4D88), size: 22),
            ),
          ),
          const SizedBox(width: 6),

          // 图片按钮
          GestureDetector(
            onTap: widget.uploading ? null : widget.onImageTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D88).withOpacity(0.1),
              ),
              child: widget.uploading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFFF4D88)),
                    )
                  : const Icon(Icons.image_outlined,
                      color: Color(0xFFFF4D88), size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // 输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(fontSize: 15),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 发送按钮
          GestureDetector(
            onTap: _hasText ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasText
                    ? const Color(0xFFFF4D88)
                    : const Color(0xFFFF4D88).withOpacity(0.3),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
