import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/network_aware.dart';
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
    // 延迟初始化，避免阻塞 UI 渲染
    Future.microtask(() {
      _setupServices();
      _setupFCM();
    });
  }

  void _setupServices() {
    try {
      ref.read(heartbeatServiceProvider).start();
    } catch (e) {
      debugPrint('[春水圈] heartbeat启动失败: $e');
    }
    try {
      ref.read(webSocketServiceProvider).connect();
    } catch (e) {
      debugPrint('[春水圈] WebSocket连接失败: $e');
    }
  }

  Future<void> _setupFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        try {
          await ref.read(dioProvider).put('/api/users/fcm-token',
              data: {'token': token});
        } catch (_) {}
      }

      messaging.onTokenRefresh.listen((token) async {
        try {
          await ref.read(dioProvider).put('/api/users/fcm-token',
              data: {'token': token});
        } catch (_) {}
      });

      FirebaseMessaging.onMessage.listen((message) {
        if (!mounted) return;
        final data = message.data;
        if (data['type'] == 'new_match') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('有人和你心意相通 💕'),
              action: SnackBarAction(
                label: '去看看',
                onPressed: () => ref.read(routerProvider).go('/matches'),
              ),
              backgroundColor: const Color(0xFFFF4D88),
            ),
          );
        } else if (data['type'] == 'new_message') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data['senderName'] ?? 'Ta'}给你发了消息'),
              backgroundColor: const Color(0xFFFF4D88),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (data['type'] == 'gift_received') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('收到一份心意 🎁 来自${data['senderName'] ?? 'Ta'}'),
              backgroundColor: const Color(0xFFFF4D88),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

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
    } catch (e) {
      debugPrint('[春水圈] FCM设置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '春水圈',
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => NetworkAwareBanner(child: child!),
    );
  }
}
