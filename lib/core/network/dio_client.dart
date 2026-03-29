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

  return dio;
});
