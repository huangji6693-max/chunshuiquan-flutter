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

  // 网络抖动自动重试——指数退避，GET最多3次，幂等写操作最多1次
  dio.interceptors.add(InterceptorsWrapper(
    onError: (error, handler) async {
      final opts = error.requestOptions;
      final retryCount = (opts.extra['_retryCount'] as int?) ?? 0;

      // 可重试的错误类型
      final isNetwork = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
      final isServerError = error.response?.statusCode != null &&
          error.response!.statusCode! >= 500;
      final isRetryable = isNetwork || isServerError;

      // GET最多重试3次，PUT/DELETE最多1次，POST不重试
      final method = opts.method.toUpperCase();
      final maxRetries = method == 'GET' ? 3 : (method == 'PUT' || method == 'DELETE') ? 1 : 0;

      // 不重试认证错误
      final status = error.response?.statusCode;
      if (status == 401 || status == 403 || status == 429) {
        return handler.next(error);
      }

      if (isRetryable && retryCount < maxRetries) {
        opts.extra['_retryCount'] = retryCount + 1;
        // 指数退避：1s → 2s → 4s
        await Future.delayed(Duration(seconds: 1 << retryCount));
        try {
          final res = await dio.fetch(opts);
          return handler.resolve(res);
        } catch (_) {
          // 重试也失败，走下方handler.next交给调用方处理
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});
