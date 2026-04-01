import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/data/auth_repository.dart';
import '../../coins/presentation/coin_shop_screen.dart';
import '../../coins/data/coin_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(coinBalanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ====== 钱包卡片 ======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CoinShopScreen())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D88).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('我的钱包',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              balanceAsync.when(
                                data: (c) => Text('$c',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800)),
                                loading: () => const Text('...',
                                    style: TextStyle(color: Colors.white70)),
                                error: (_, __) => const Text('--',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                              const SizedBox(width: 4),
                              const Text('金币',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('充值',
                          style: TextStyle(
                              color: Color(0xFFFF4D88),
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ====== 账号与安全 ======
          _SectionHeader(title: '账号与安全'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: '个人资料',
            onTap: () => context.go('/profile'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: '账号安全',
            subtitle: '密码、绑定手机',
            onTap: () => _showComingSoon(context),
          ),
          _SettingsTile(
            icon: Icons.block,
            title: '黑名单管理',
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: 12),

          // ====== 通知与隐私 ======
          _SectionHeader(title: '通知与隐私'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: '消息通知',
            subtitle: '推送、声音、振动',
            onTap: () => _showComingSoon(context),
          ),
          _SettingsTile(
            icon: Icons.visibility_off_outlined,
            title: '隐身模式',
            subtitle: '不出现在发现页',
            trailing: Switch(
              value: false,
              onChanged: (_) => _showComingSoon(context),
              activeColor: const Color(0xFFFF4D88),
            ),
          ),
          _SettingsTile(
            icon: Icons.location_off_outlined,
            title: '隐藏距离',
            subtitle: '对方看不到你的距离',
            trailing: Switch(
              value: false,
              onChanged: (_) => _showComingSoon(context),
              activeColor: const Color(0xFFFF4D88),
            ),
          ),

          const SizedBox(height: 12),

          // ====== 关于 ======
          _SectionHeader(title: '关于'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => launchUrl(
              Uri.parse('https://huangji6693-max.github.io/chunshuiquan-privacy'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '用户协议',
            trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => launchUrl(
              Uri.parse('https://huangji6693-max.github.io/chunshuiquan-privacy/terms'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: '关于春水圈',
            subtitle: 'v1.0.0',
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: 12),

          // ====== 危险操作 ======
          _SectionHeader(title: ''),
          _SettingsTile(
            icon: Icons.logout,
            iconColor: Colors.orange,
            title: '退出登录',
            titleColor: Colors.orange,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            title: '删除账号',
            titleColor: Colors.red,
            onTap: () => _confirmDelete(context, ref),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('功能即将上线'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('删除账号'),
          ],
        ),
        content: const Text(
          '此操作不可撤销。\n\n你的所有数据（照片、匹配、聊天记录、金币）将被永久删除。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(dioProvider).delete('/api/users/me');
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) context.go('/auth/login');
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.message}')),
        );
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)));
      }
    }
  }
}

// ====== 组件 ======

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Text(title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFFFF4D88)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFFFF4D88), size: 20),
        ),
        title: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: titleColor ?? Colors.black87,
            )),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20)
                : null),
        onTap: onTap,
      ),
    );
  }
}
