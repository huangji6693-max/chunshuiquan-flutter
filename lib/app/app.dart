import '../shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/theme_provider.dart';
import '../shared/widgets/network_aware.dart';
import '../core/network/dio_client.dart';
import '../core/services/heartbeat_service.dart';
import '../core/network/websocket_service.dart';
import '../features/notifications/providers/notifications_provider.dart';
import '../features/notifications/domain/notification_item.dart';
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
      // FCM 初始化延迟1秒，避免与心跳和 WebSocket 并发请求导致卡顿
      Future.delayed(const Duration(seconds: 1), _setupFCM);
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
        } catch (_) {
          // FCM token上报失败不阻塞，下次启动会重试
        }
      }

      messaging.onTokenRefresh.listen((token) async {
        try {
          await ref.read(dioProvider).put('/api/users/fcm-token',
              data: {'token': token});
        } catch (_) {
          // token刷新上报失败静默，下次刷新会重试
        }
      });

      FirebaseMessaging.onMessage.listen((message) {
        if (!mounted) return;
        final data = message.data;
        final notifier = ref.read(notificationsProvider.notifier);
        final senderName = data['senderName'] ?? 'Ta';

        if (data['type'] == 'new_match') {
          notifier.addNotification(NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: NotificationType.match,
            title: '和你心意相通 💕',
            senderName: senderName,
            avatarUrl: data['avatarUrl'],
            createdAt: DateTime.now(),
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('有人和你心意相通 💕'),
              action: SnackBarAction(
                label: '去看看',
                onPressed: () => ref.read(routerProvider).go('/matches'),
              ),
              backgroundColor: Dt.pink,
            ),
          );
        } else if (data['type'] == 'new_message') {
          notifier.addNotification(NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: NotificationType.message,
            title: '给你发了消息',
            senderName: senderName,
            avatarUrl: data['avatarUrl'],
            createdAt: DateTime.now(),
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$senderName给你发了消息'),
              backgroundColor: Dt.pink,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (data['type'] == 'gift_received') {
          notifier.addNotification(NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: NotificationType.match,
            title: '送了你一份礼物 🎁',
            senderName: senderName,
            avatarUrl: data['avatarUrl'],
            createdAt: DateTime.now(),
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('收到一份心意 🎁 来自$senderName'),
              backgroundColor: Dt.pink,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (data['type'] == 'call_invite') {
          final matchId = data['matchId'];
          final callerName = data['callerName'] ?? 'Ta';
          if (matchId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$callerName 邀请你语音通话 📞'),
                action: SnackBarAction(
                  label: '接听',
                  onPressed: () => ref.read(routerProvider).go('/call/$matchId'),
                ),
                backgroundColor: Dt.pink,
                duration: const Duration(seconds: 15),
              ),
            );
          }
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
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: '春水圈',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.theme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => NetworkAwareBanner(child: child!),
    );
  }
}
