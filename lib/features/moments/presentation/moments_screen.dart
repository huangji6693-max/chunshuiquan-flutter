import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/moment_repository.dart';
import '../providers/moments_provider.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/animated_empty_state.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/design_tokens.dart';

class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(momentsTimelineProvider);

    return Scaffold(
      
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Dt.pinkLight, Dt.pink],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            const Text('动态'),
          ],
        ),
        
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Dt.pink, Dt.orange]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () async {
              final created = await context.push<bool>('/moments/create');
              if (created == true) ref.invalidate(momentsTimelineProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async => ref.invalidate(momentsTimelineProvider),
        child: momentsAsync.when(
          data: (moments) {
            if (moments.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.dynamic_feed,
                title: '分享你的故事',
                subtitle: '一张照片、一句心情，让Ta看到真实的你',
                action: TextButton(
                  onPressed: () => context.push('/moments/create'),
                  child: const Text('发布动态'),
                ),
              );
            }

            final notifier = ref.read(momentsTimelineProvider.notifier);
            return NotificationListener<ScrollNotification>(
              onNotification: (scroll) {
                if (scroll.metrics.pixels > scroll.metrics.maxScrollExtent - 200) {
                  notifier.loadMore();
                }
                return false;
              },
              child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: moments.length + (notifier.hasMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= moments.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: _MomentCard(
                          moment: moments[i],
                          onLikeToggled: () => ref.invalidate(momentsTimelineProvider),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            );
          },
          loading: () => const MomentsSkeleton(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Text('请检查网络后重试', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(momentsTimelineProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====== 动态卡片 ======
class _MomentCard extends ConsumerStatefulWidget {
  final MomentItem moment;
  final VoidCallback onLikeToggled;

  const _MomentCard({required this.moment, required this.onLikeToggled});

  @override
  ConsumerState<_MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<_MomentCard> {
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.moment.likedByMe;
    _likeCount = widget.moment.likeCount;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：头像 + 名字 + 时间
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: m.authorAvatar != null
                      ? ResizeImage(
                          CachedNetworkImageProvider(m.authorAvatar!),
                          width: 200,
                        )
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  child: m.authorAvatar == null
                      ? Text(m.authorName[0],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Dt.pink))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m.authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (m.authorVipTier != null &&
                              m.authorVipTier != 'none') ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 15,
                                color: m.authorVipTier == 'diamond'
                                    ? const Color(0xFFE040FB)
                                    : Dt.vipGold),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(_formatTime(m.createdAt),
                              style: TextStyle(
                                  fontSize: 12, letterSpacing: 0.3, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          if (m.location?.isNotEmpty == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.location_on,
                                size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            Text(m.location!,
                                style: TextStyle(
                                    fontSize: 12, letterSpacing: 0.3, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 文字内容
          if (m.content?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(m.content!,
                  style: const TextStyle(fontSize: 15, height: 1.6, letterSpacing: 0.1)),
            ),

          // 图片网格
          if (m.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildImageGrid(m.imageUrls),
            ),

          // 底部互动栏
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                // 点赞
                _InteractionBtn(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Dt.pink : Theme.of(context).colorScheme.onSurfaceVariant,
                  label: _likeCount > 0 ? '$_likeCount' : '赞',
                  onTap: _handleLike,
                ),
                // 评论
                _InteractionBtn(
                  icon: Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  label: m.commentCount > 0 ? '${m.commentCount}' : '评论',
                  onTap: () => _showComments(context),
                ),
                // 分享
                _InteractionBtn(
                  icon: Icons.share_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  label: '分享',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: CachedNetworkImage(
            imageUrl: urls.first,
            fit: BoxFit.cover,
            memCacheWidth: 800,
            width: double.infinity,
          ),
        ),
      );
    }

    final crossAxisCount = urls.length <= 4 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.cover, memCacheWidth: 400),
      ),
    );
  }

  Future<void> _handleLike() async {
    HapticFeedback.lightImpact();
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      await ref.read(momentRepositoryProvider).toggleLike(widget.moment.id);
    } catch (_) {
      setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
      });
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(momentId: widget.moment.id),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}

// ====== 互动按钮 ======
class _InteractionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _InteractionBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== 评论底部弹窗 ======
class _CommentsSheet extends ConsumerStatefulWidget {
  final String momentId;
  const _CommentsSheet({required this.momentId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<CommentItem>? _comments;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments =
          await ref.read(momentRepositoryProvider).getComments(widget.momentId);
      if (mounted) setState(() { _comments = comments; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(momentRepositoryProvider).addComment(widget.momentId, text);
      _ctrl.clear();
      _loadComments();
    } catch (e) {
      debugPrint('发送评论失败: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      height: mq.size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 手柄
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('评论',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ),

          // 评论列表
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : (_comments == null || _comments!.isEmpty)
                    ? Center(
                        child: Text('还没有评论',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments!.length,
                        itemBuilder: (_, i) {
                          final c = _comments![i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: c.authorAvatar != null
                                      ? ResizeImage(
                                          CachedNetworkImageProvider(
                                              c.authorAvatar!),
                                          width: 200,
                                        )
                                      : null,
                                  child: c.authorAvatar == null
                                      ? Text(c.authorName[0],
                                          style: const TextStyle(fontSize: 12))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.authorName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      const SizedBox(height: 2),
                                      Text(c.content,
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // 输入框
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 8, mq.padding.bottom + 8),
            decoration: BoxDecoration(
              
              border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: '发表评论...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Dt.pink,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
