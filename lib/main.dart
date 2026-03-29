import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/session_provider.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // session 过期回调在 app.dart 构建后由 router 填充
        // 这里提供一个安全默认值，router.dart 会在初始化后覆盖
        sessionExpiredCallbackProvider.overrideWith((ref) {
          // router 初始化后会通过 ref.watch(routerProvider) 拿到实例
          // 真正的跳转逻辑在 app.dart 的 routerProvider 里处理
          return () async {};
        }),
      ],
      child: const ChunShuiQuanApp(),
    ),
  );
}
