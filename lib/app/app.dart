import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../shared/theme/app_theme.dart';
import '../core/network/session_provider.dart';
import '../core/network/dio_client.dart';
import 'router.dart';

class ChunShuiQuanApp extends ConsumerStatefulWidget {
  const ChunShuiQuanApp({super.key});

  @override
  ConsumerState<ChunShuiQuanApp> createState() => _ChunShuiQuanAppState();
}

class _ChunShuiQuanAppState extends ConsumerState<ChunShuiQuanApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging? messaging;

    try {
      messaging = FirebaseMessaging.instance;
    } catch (_) {
      return;
    }

    // 获取 FCM Token 并上报后端
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await ref.read(dioProvider).put('/api/users/fcm-token',
            data: {'token': token});
      }
    } catch (_) {}

    // Token 刷新时重新上报
    messaging.onTokenRefresh.listen((token) async {
      try {
        await ref.read(dioProvider).put('/api/users/fcm-token',
            data: {'token': token});
      } catch (_) {}
    });

    // 前台收到推送
    FirebaseMessaging.onMessage.listen((message) {
      final router = ref.read(routerProvider);
      final data = message.data;
      if (data['type'] == 'new_match') {
        // 显示 SnackBar 提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💕 你有新的匹配！'),
            action: SnackBarAction(
              label: '查看',
              onPressed: () => router.go('/matches'),
            ),
            backgroundColor: const Color(0xFFFF4D88),
          ),
        );
      }
    });

    // 点击通知打开 App
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final router = ref.read(routerProvider);
      final data = message.data;
      final matchId = data['matchId'];
      if (data['type'] == 'new_message' && matchId != null) {
        router.go('/chat/$matchId');
      } else if (data['type'] == 'new_match') {
        router.go('/matches');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '春水圈',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
