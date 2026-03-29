import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/app.dart';
import 'core/network/session_provider.dart';

// 后台消息处理（必须是顶级函数）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 后台消息静默处理，点击后由 onMessageOpenedApp 处理
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp();

  // 注册后台消息处理
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 请求推送权限（iOS）
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    ProviderScope(
      overrides: [
        sessionExpiredCallbackProvider.overrideWith((ref) => () async {}),
      ],
      child: const ChunShuiQuanApp(),
    ),
  );
}
