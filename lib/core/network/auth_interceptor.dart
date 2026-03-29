import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_manager.dart';

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  throw UnimplementedError('Must be overridden with dio instance');
});

class AuthInterceptor extends Interceptor {
  static const _kSkipAuth = 'skipAuth';
  static const _kIsRetry  = '_isRetry';

  final Dio _dio;
  final TokenManager _tokenManager;
  final Future<void> Function() _onSessionExpired;

  Completer<String>? _refreshCompleter;

  AuthInterceptor({
    required Dio dio,
    required TokenManager tokenManager,
    required Future<void> Function() onSessionExpired,
  })  : _dio = dio,
        _tokenManager = tokenManager,
        _onSessionExpired = onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_kSkipAuth] == true) return handler.next(options);
    final token = await _tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        opts.extra[_kSkipAuth] == true ||
        opts.extra[_kIsRetry]  == true) {
      return handler.next(err);
    }

    try {
      final newToken = await _getOrRefreshToken();
      final response = await _retry(opts, newToken);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String> _getOrRefreshToken() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    _refreshCompleter = Completer<String>();
    try {
      final newToken = await _doRefresh();
      final completer = _refreshCompleter!;
      _refreshCompleter = null;  // 先置 null 再 complete，避免逻辑竞态
      completer.complete(newToken);
      return newToken;
    } catch (e) {
      final completer = _refreshCompleter!;
      _refreshCompleter = null;
      completer.completeError(e);
      rethrow;
    }
  }

  Future<String> _doRefresh() async {
    final refreshToken = await _tokenManager.getRefreshToken();
    if (refreshToken == null) {
      await _clearAndLogout();
      throw _sessionExpiredError();
    }

    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_kSkipAuth: true}),
      );

      final data = resp.data!;
      final newAccess  = data['token']        as String;
      final newRefresh = data['refreshToken'] as String? ?? refreshToken;

      await _tokenManager.saveTokens(
        accessToken:  newAccess,
        refreshToken: newRefresh,
      );
      return newAccess;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _clearAndLogout();
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions opts, String token) {
    return _dio.request<dynamic>(
      opts.path,
      data: opts.data,
      queryParameters: opts.queryParameters,
      options: Options(
        method: opts.method,
        headers: {...opts.headers, 'Authorization': 'Bearer $token'},
        contentType: opts.contentType,
        responseType: opts.responseType,
        sendTimeout: opts.sendTimeout,
        receiveTimeout: opts.receiveTimeout,
        extra: {...opts.extra, _kIsRetry: true},
      ),
    );
  }

  Future<void> _clearAndLogout() async {
    await _tokenManager.clearTokens();
    await _onSessionExpired();
  }

  DioException _sessionExpiredError() => DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        error: 'Session expired',
      );
}
