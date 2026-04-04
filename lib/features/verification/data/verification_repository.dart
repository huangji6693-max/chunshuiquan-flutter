import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(ref.watch(dioProvider)),
);

class VerificationRepository {
  final Dio _dio;
  VerificationRepository(this._dio);

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final res = await _dio.get('/api/verification/status');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '查询认证状态失败');
    }
  }

  Future<Map<String, dynamic>> submit({
    required String realName,
    required String idPhotoUrl,
    required String selfieUrl,
  }) async {
    try {
      final res = await _dio.post('/api/verification/submit', data: {
        'realName': realName,
        'idPhotoUrl': idPhotoUrl,
        'selfieUrl': selfieUrl,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '提交认证失败');
    }
  }
}
