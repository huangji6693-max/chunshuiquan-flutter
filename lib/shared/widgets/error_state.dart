import 'package:flutter/material.dart';

/// 统一的错误状态组件
/// 网络错误、加载失败等场景通用
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colors.error),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '网络开小差了',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
