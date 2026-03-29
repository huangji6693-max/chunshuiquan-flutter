import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

enum ReportReason {
  inappropriatePhoto('INAPPROPRIATE_PHOTO', '不雅照片'),
  spam('SPAM', '垃圾信息'),
  fakeProfile('FAKE_PROFILE', '虚假资料'),
  harassment('HARASSMENT', '骚扰行为'),
  underage('UNDERAGE', '未成年人');

  final String value;
  final String label;
  const ReportReason(this.value, this.label);
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(dioProvider)),
);

class ReportRepository {
  final Dio _dio;
  ReportRepository(this._dio);

  Future<void> reportUser({
    required String reportedId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      await _dio.post('/api/reports', data: {
        'reportedId': reportedId,
        'reason': reason.value,
        if (description != null && description.isNotEmpty) 'description': description,
      });
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '举报失败');
    }
  }

  Future<void> blockUser(String targetId) async {
    try {
      await _dio.post('/api/blocks/$targetId');
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '屏蔽失败');
    }
  }

  Future<void> unblockUser(String targetId) async {
    try {
      await _dio.delete('/api/blocks/$targetId');
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '取消屏蔽失败');
    }
  }
}
