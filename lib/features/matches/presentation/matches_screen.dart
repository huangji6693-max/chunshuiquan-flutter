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
      appBar: AppBar(title: const Text('匹配')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (matches) => matches.isEmpty
            ? const Center(child: Text('还没有匹配\n去滑卡认识新朋友吧 💕',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: matches.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final m = matches[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: m.otherAvatarUrl != null
                          ? CachedNetworkImageProvider(m.otherAvatarUrl!)
                          : null,
                      child: m.otherAvatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(m.otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: m.otherBio != null ? Text(m.otherBio!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/chat/${m.matchId}'),
                  );
                },
              ),
      ),
    );
  }
}
