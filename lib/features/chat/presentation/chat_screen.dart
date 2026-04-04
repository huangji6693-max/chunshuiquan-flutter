import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../../gifts/presentation/gift_panel.dart';
import '../../gifts/presentation/gift_animation_overlay.dart';
import '../providers/messages_provider.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/network/websocket_service.dart';
import '../../profile/data/upload_repository.dart';
import '../data/message_repository.dart';
import '../../../core/network/dio_client.dart';

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
    } catch (_) {
      // WebSocket未连接时静默，不影响HTTP轮询
    }
  }

  @override
  void dispose() {
    try {
      ref.read(webSocketServiceProvider).unsubscribeChatChannel(widget.matchId);
    } catch (_) {
      // dispose时静默，资源即将释放
    }
    super.dispose();
  }

  List<types.Message> _toUiMessages(
      List<ChatMessage> messages, String myId, String? partnerName, String? partnerAvatar) {
    return messages.map((m) {
      final isMe = m.senderId == myId;
      final author = types.User(
        id: m.senderId,
        firstName: isMe ? null : (partnerName ?? 'Ta'),
        imageUrl: isMe ? null : partnerAvatar,
      );

      // 识别图片消息: "[图片] https://..."
      if (m.content.startsWith('[图片] ')) {
        final url = m.content.substring(5).trim();
        return types.ImageMessage(
          id: m.id,
          uri: url,
          name: 'photo',
          size: 0,
          createdAt: m.createdAt.millisecondsSinceEpoch,
          author: author,
          metadata: {'isRead': m.isRead},
        );
      }

      return types.TextMessage(
        id: m.id,
        text: m.content,
        createdAt: m.createdAt.millisecondsSinceEpoch,
        author: author,
        metadata: {'isRead': m.isRead},
      );
    }).toList()
      ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
  }

  Future<void> _handleSend(types.PartialText msg) async {
    final myId = ref.read(currentUserProvider).asData?.value.id ?? '';
    if (myId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户信息加载中，请稍后重试')),
        );
      }
      return;
    }
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

    return Scaffold(
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha:0.2),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
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
                    icon: Icon(Icons.arrow_back_ios,
                        size: 20, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // 对方头像 + Hero过渡
                  Hero(
                    tag: 'avatar_${widget.matchId}',
                    child: CircleAvatar(
                    radius: 22,
                    backgroundImage: widget.partnerAvatarUrl != null &&
                            widget.partnerAvatarUrl!.isNotEmpty
                        ? ResizeImage(
                            CachedNetworkImageProvider(widget.partnerAvatarUrl!),
                            width: 200,
                          )
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: widget.partnerAvatarUrl == null ||
                            widget.partnerAvatarUrl!.isEmpty
                        ? Icon(Icons.person,
                            size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant)
                        : null,
                  ),
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
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface),
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
                        color: const Color(0xFFFF4D88).withValues(alpha:0.1),
                      ),
                      child: const Icon(Icons.call_outlined,
                          color: Color(0xFFFF4D88), size: 20),
                    ),
                    onPressed: () {
                      context.push('/call/${widget.matchId}', extra: {
                        'partnerName': widget.partnerName ?? '对方',
                        'partnerAvatarUrl': widget.partnerAvatarUrl,
                      });
                    },
                  ),

                  // 视频通话按钮（预留）
                  IconButton(
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D88).withValues(alpha:0.1),
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
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.wifi_off, size: 48, color: Theme.of(context).colorScheme.error), const SizedBox(height: 12), Text('消息加载失败，下拉重试', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
        data: (messages) => Chat(
          messages: _toUiMessages(
              messages, myId, widget.partnerName, widget.partnerAvatarUrl),
          onSendPressed: _handleSend,
          onEndReached: () => ref
              .read(messagesProvider(widget.matchId).notifier)
              .loadMore(),
          onEndReachedThreshold: 0.75,
          user: types.User(id: myId),
          showUserAvatars: true,
          showUserNames: false,
          theme: DefaultChatTheme(
            // 自己的消息：品牌粉
            primaryColor: const Color(0xFFFF4D88),
            // 对方的消息：暗色卡片
            secondaryColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            backgroundColor: Theme.of(context).colorScheme.surface,
            inputBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            inputBorderRadius: BorderRadius.circular(28),
            messageBorderRadius: 20,
            inputTextColor: Theme.of(context).colorScheme.onSurface,
            inputTextStyle: const TextStyle(fontSize: 15),
            inputPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            inputContainerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha:0.3),
                ),
              ),
            ),
            sentMessageBodyTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
            receivedMessageBodyTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              height: 1.4,
            ),
            dateDividerTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            sendButtonIcon: const Icon(
              Icons.send_rounded,
              color: Color(0xFFFF4D88),
              size: 24,
            ),
            sendingIcon: Icon(
              Icons.access_time,
              size: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
            emptyChatPlaceholderTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        const Color(0xFFFF4D88).withValues(alpha:0.1),
                        const Color(0xFFFF8A5C).withValues(alpha:0.1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      size: 36, color: Color(0xFFFF4D88)),
                ),
                const SizedBox(height: 16),
                Text(
                  '说点什么打破沉默吧 ☺️',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text('也许一句Hi就是故事的开头',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          avatarBuilder: (author) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: author.imageUrl != null
                  ? ResizeImage(
                      CachedNetworkImageProvider(author.imageUrl!),
                      width: 200,
                    )
                  : null,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha:0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // + 按钮（图片 + 礼物）
          GestureDetector(
            onTap: widget.uploading ? null : () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.image_outlined, color: Color(0xFFFF4D88), size: 22),
                        ),
                        title: const Text('图片'),
                        onTap: () { Navigator.pop(context); widget.onImageTap(); },
                      ),
                      ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF4D88).withValues(alpha: 0.15),
                                const Color(0xFFFF8A5C).withValues(alpha: 0.15),
                              ],
                            ),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF4D88), size: 22),
                        ),
                        title: const Text('礼物'),
                        onTap: () { Navigator.pop(context); widget.onGiftTap(); },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
              ),
              child: widget.uploading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFFF4D88)),
                    )
                  : const Icon(Icons.add_circle_outline,
                      color: Color(0xFFFF4D88), size: 24),
            ),
          ),
          const SizedBox(width: 8),

          // 输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
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

          // 发送 或 语音按钮
          _hasText
              ? GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D88).withValues(alpha:0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                )
              : GestureDetector(
                  onLongPress: () {
                    // 语音录制（长按提示）
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('长按录音，松手发送'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4D88).withValues(alpha:0.1),
                    ),
                    child: const Icon(Icons.mic_none,
                        color: Color(0xFFFF4D88), size: 22),
                  ),
                ),
        ],
      ),
    );
  }
}
