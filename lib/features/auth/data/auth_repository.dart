import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_manager.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenManagerProvider)),
);

class AuthRepository {
  final Dio _dio;
  final TokenManager _tm;

  AuthRepository(this._dio, this._tm);

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String birthDate,
    required String gender,
  }) async {
    try {
      final res = await _dio.post('/api/auth/register', data: {
        'name': name, 'email': email, 'password': password,
        'birthDate': birthDate, 'gender': gender,
      });
      return _handleAuthResponse(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email, 'password': password,
      });
      return _handleAuthResponse(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> getMe() async {
    try {
      final res = await _dio.get('/api/users/me');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 登出：先调后端吊销token，再清除本地存储
  Future<void> logout() async {
    try {
      final refreshToken = await _tm.getRefreshToken();
      await _dio.post('/api/auth/logout', data: {
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      });
    } catch (_) {
      // 后端调用失败不阻断登出流程
    }
    await _tm.clearTokens();
  }

  Future<UserProfile> _handleAuthResponse(dynamic rawData) async {
    final data = rawData;
    if (data is! Map<String, dynamic>) throw AppException.server('响应格式错误');
    final token = data['token'];
    if (token is! String || token.isEmpty) throw AppException.server('认证失败：未收到 token');
    final refreshToken = data['refreshToken'] as String?;
    await _tm.saveTokens(
      accessToken: token,
      refreshToken: refreshToken ?? '',  // 后端必须返回 refreshToken
    );
    return UserProfile.fromJson(data);
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/api/users/me');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException e) {
    if (e.response?.statusCode == 401) return AppException.unauthorized();
    // [fix] 409 Conflict — 邮箱已注册, 前端可识别后跳转登录页
    if (e.response?.statusCode == 409) {
      final msg = e.response?.data?['error'] ?? '该邮箱已注册';
      return AppException.conflict(msg);
    }
    if (e.response?.statusCode == 400) {
      final raw = e.response?.data;
      String msg = '请求错误';
      if (raw is Map) {
        msg = raw['error']?.toString() ?? raw['message']?.toString() ?? '请求错误';
        // 携带详细字段验证错误
        final details = raw['details'];
        if (details is List && details.isNotEmpty) {
          msg = '$msg: ${details.first}';
        }
      }
      return AppException.validation(msg);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppException.network('网络连接超时');
    }
    // [debug] 500 时附带 detail 字段帮助主人定位 Railway 问题
    final raw = e.response?.data;
    String? serverMsg;
    if (raw is Map) {
      serverMsg = raw['error']?.toString();
      final detail = raw['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        serverMsg = '${serverMsg ?? "服务器错误"}\n$detail';
      }
    }
    return AppException.server(serverMsg ?? '服务器错误');
  }
}
