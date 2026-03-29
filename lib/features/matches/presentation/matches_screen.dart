import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/match_repository.dart';

final matchesProvider = FutureProvider<List<MatchItem>>((ref) {
  return ref.watch(matchRepositoryProvider).fetchMatches();
});

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
          ).createShader(bounds),
          child: const Text('匹配',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ),
      body: state.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4D88))),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_outline,
                      size: 72, color: Color(0xFFFFCDD2)),
                  const SizedBox(height: 16),
                  const Text('还没有匹配',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 8),
                  Text('去滑卡认识新朋友吧 💕',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          final newMatches =
              matches.where((m) => m.isNew == true).toList();
          final conversations =
              matches.where((m) => m.isNew != true).toList();

          return CustomScrollView(
            slivers: [
              // 新匹配横向滚动
              if (newMatches.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('新匹配',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: newMatches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          _NewMatchAvatar(match: newMatches[i]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Divider(height: 1, color: Colors.grey.shade100),
                ),
              ],

              // 消息列表
              if (conversations.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('消息',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500)),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ConversationTile(match: conversations[i]),
                  childCount: conversations.length,
                ),
              ),

              // 如果没有 conversations，显示全部新匹配
              if (conversations.isEmpty && newMatches.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('快去发送第一条消息吧 👋',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ),
                  ),
                ),

              // 底部padding防止Tab bar遮挡
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _NewMatchAvatar extends StatelessWidget {
  final MatchItem match;
  const _NewMatchAvatar({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/chat/${match.matchId}', extra: {
        'partnerName': match.otherName,
        'partnerAvatarUrl': match.otherAvatarUrl,
      }),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D88).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: CircleAvatar(
              radius: 32,
              backgroundImage: match.otherAvatarUrl != null
                  ? CachedNetworkImageProvider(match.otherAvatarUrl!)
                  : null,
              backgroundColor: Colors.white,
              child: match.otherAvatarUrl == null
                  ? Text(
                      match.otherName.isNotEmpty
                          ? match.otherName[0]
                          : '?',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              match.otherName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final MatchItem match;
  const _ConversationTile({required this.match});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: match.otherAvatarUrl != null
            ? CachedNetworkImageProvider(match.otherAvatarUrl!)
            : null,
        backgroundColor: const Color(0xFFF5F5F5),
        child: match.otherAvatarUrl == null
            ? Text(
                match.otherName.isNotEmpty ? match.otherName[0] : '?',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              )
            : null,
      ),
      title: Text(match.otherName,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(match.otherBio ?? '点击开始聊天',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.grey, size: 20),
      onTap: () => context.go('/chat/${match.matchId}', extra: {
        'partnerName': match.otherName,
        'partnerAvatarUrl': match.otherAvatarUrl,
      }),
    );
  }
}
