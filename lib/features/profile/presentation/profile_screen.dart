import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(
      FutureProvider((ref) => ref.watch(authRepositoryProvider).getMe()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundImage: user.firstAvatar.isNotEmpty
                    ? NetworkImage(user.firstAvatar)
                    : null,
                child: user.firstAvatar.isEmpty ? const Icon(Icons.person, size: 52) : null,
              ),
              const SizedBox(height: 16),
              Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(user.bio!, style: const TextStyle(color: Colors.grey, fontSize: 15),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              _InfoRow(icon: Icons.email, label: user.email),
              if (user.jobTitle != null && user.jobTitle!.isNotEmpty)
                _InfoRow(icon: Icons.work, label: user.jobTitle!),
              if (user.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: user.tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
