import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final boostRepositoryProvider = Provider<BoostRepository>(
  (ref) => BoostRepository(ref.watch(dioProvider)),
);

class BoostRepository {
  final Dio _dio;
  BoostRepository(this._dio);

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final res = await _dio.get('/api/boost/status');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '查询加速状态失败');
    }
  }

  Future<Map<String, dynamic>> activate() async {
    try {
      final res = await _dio.post('/api/boost');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '激活加速失败');
    }
  }
}
