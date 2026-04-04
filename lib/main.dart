import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/app.dart';
import 'core/network/session_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // 后台handler中Firebase初始化失败静默，不影响主进程
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 初始化——失败不阻塞启动
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sessionExpiredCallbackProvider.overrideWith((ref) => () async {}),
      ],
      child: const ChunShuiQuanApp(),
    ),
  );
}
