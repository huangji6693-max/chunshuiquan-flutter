import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../shared/theme/app_theme.dart';
import '../core/network/session_provider.dart';
import '../core/network/dio_client.dart';
import '../core/services/heartbeat_service.dart';
import '../core/network/websocket_service.dart';
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
    _setupServices();
  }

  /// 初始化心跳和 WebSocket 服务
  void _setupServices() {
    // 启动心跳服务（维护在线状态）
    try {
      ref.read(heartbeatServiceProvider).start();
    } catch (_) {}

    // 连接 WebSocket
    try {
      ref.read(webSocketServiceProvider).connect();
    } catch (_) {}
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('你有新的匹配！'),
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
