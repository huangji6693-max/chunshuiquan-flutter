import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_manager.dart';
import 'auth_interceptor.dart';
import 'session_provider.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://chunshuiquan-backend-production.up.railway.app',
);

final dioProvider = Provider<Dio>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  final onSessionExpired = ref.watch(sessionExpiredCallbackProvider);

  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: const {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    tokenManager: tokenManager,
    onSessionExpired: onSessionExpired,
  ));

  // 网络抖动自动重试（仅GET请求，最多1次）
  dio.interceptors.add(InterceptorsWrapper(
    onError: (error, handler) async {
      final isTimeout = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
      final isGet = error.requestOptions.method == 'GET';
      final isRetry = error.requestOptions.extra['_retried'] == true;

      if (isTimeout && isGet && !isRetry) {
        error.requestOptions.extra['_retried'] = true;
        try {
          final res = await dio.fetch(error.requestOptions);
          return handler.resolve(res);
        } catch (_) {}
      }
      handler.next(error);
    },
  ));

  return dio;
});
