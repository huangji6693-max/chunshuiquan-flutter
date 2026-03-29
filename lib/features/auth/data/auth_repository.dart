import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(authStorageProvider)),
);

class AuthRepository {
  final Dio _dio;
  final AuthStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String birthDate,
    required String gender,
  }) async {
    try {
      final res = await _dio.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'birthDate': birthDate,
        'gender': gender,
      });
      final data = res.data;
      if (data is! Map<String, dynamic>) throw AppException.server('响应格式错误');
      final token = data['token'];
      if (token is! String || token.isEmpty) throw AppException.server('注册失败：未收到 token');
      await _storage.saveToken(token);
      return UserProfile.fromJson(data['profile'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data;
      if (data is! Map<String, dynamic>) throw AppException.server('响应格式错误');
      final token = data['token'];
      if (token is! String || token.isEmpty) throw AppException.server('登录失败：未收到 token');
      await _storage.saveToken(token);
      return UserProfile.fromJson(data['profile'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> getMe() async {
    try {
      final res = await _dio.get('/api/users/me');
      return UserProfile.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() => _storage.deleteToken();

  AppException _handleError(DioException e) {
    if (e.response?.statusCode == 401) return AppException.unauthorized();
    if (e.response?.statusCode == 400) {
      final msg = e.response?.data?['message'] ?? '请求错误';
      return AppException.validation(msg);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppException.network('网络连接超时');
    }
    return AppException.server(e.response?.data?['message'] ?? '服务器错误');
  }
}
