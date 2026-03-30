import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/session_provider.dart';
import '../../../core/errors/app_exception.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('春水圈'),
            subtitle: Text('当前版本 1.0.0+1'),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('开源接入策略'),
            subtitle: const Text('优先接入 GitHub 顶级开源能力，避免从零造轮子'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('当前仓库已整理 OSS 接入策略与候选清单')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://huangji6693-max.github.io/chunshuiquan-privacy'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('用户协议'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://huangji6693-max.github.io/chunshuiquan-privacy/terms'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              await ref.read(sessionExpiredCallbackProvider)();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('删除账号', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账号'),
        content: const Text('此操作不可撤销。\n\n你的所有数据（照片、匹配、聊天记录）将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(dioProvider).delete('/api/users/me');
      await ref.read(authRepositoryProvider).logout();
      await ref.read(sessionExpiredCallbackProvider)();
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.message}')),
        );
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
