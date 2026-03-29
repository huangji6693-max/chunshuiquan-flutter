import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_manager.dart';
import 'auth_interceptor.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://chunshuiquan-backend-production.up.railway.app',
);

// 外部注入 session 过期回调（由 app.dart 在启动时设置）
void Function()? _onSessionExpiredCallback;

void setSessionExpiredCallback(void Function() cb) {
  _onSessionExpiredCallback = cb;
}

final dioProvider = Provider<Dio>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);

  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: const {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    tokenManager: tokenManager,
    onSessionExpired: () async {
      await tokenManager.clearTokens();
      _onSessionExpiredCallback?.call();
    },
  ));

  return dio;
});
