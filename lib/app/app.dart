import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/theme/app_theme.dart';
import '../core/network/dio_client.dart';
import 'router.dart';

class ChunShuiQuanApp extends ConsumerWidget {
  const ChunShuiQuanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // 注入 session 过期回调 → 跳登录页
    setSessionExpiredCallback(() => router.go('/auth/login'));

    return MaterialApp.router(
      title: '春水圈',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
