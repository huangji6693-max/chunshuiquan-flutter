import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/network/session_provider.dart';

// 后台消息处理（必须是顶级函数）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase 未配置时跳过，避免后台消息初始化导致应用崩溃
  }
}

Future<void> _tryInitFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e, st) {
    debugPrint('Firebase init skipped: $e');
    debugPrintStack(stackTrace: st);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _tryInitFirebase();

  runApp(
    ProviderScope(
      overrides: [
        sessionExpiredCallbackProvider.overrideWith(
          (ref) => () async {
            final navigatorKey = ref.read(appNavigatorKeyProvider);
            final context = navigatorKey.currentContext;
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('登录已过期，请重新登录')),
              );
            }
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/auth/login',
              (route) => false,
            );
          },
        ),
      ],
      child: const ChunShuiQuanApp(),
    ),
  );
}
