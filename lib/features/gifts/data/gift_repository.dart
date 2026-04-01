import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/gift.dart';
import '../domain/gift_record.dart';

final giftRepositoryProvider = Provider<GiftRepository>(
  (ref) => GiftRepository(ref.watch(dioProvider)),
);

/// 礼物仓库 - 获取礼物列表、发送礼物、查询收发记录
class GiftRepository {
  final Dio _dio;
  GiftRepository(this._dio);

  /// 获取所有可用礼物
  Future<List<Gift>> getGifts() async {
    try {
      final res = await _dio.get('/api/gifts');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => Gift.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取礼物列表失败');
    }
  }

  /// 向匹配对象发送礼物
  Future<GiftRecord> sendGift(String matchId, int giftId) async {
    try {
      final res = await _dio.post('/api/gifts/send', data: {
        'matchId': matchId,
        'giftId': giftId,
      });
      return GiftRecord.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '发送礼物失败');
    }
  }

  /// 查询收到的礼物记录
  Future<List<GiftRecord>> getReceived() async {
    try {
      final res = await _dio.get('/api/gifts/received');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => GiftRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取收礼记录失败');
    }
  }

  /// 查询发送的礼物记录
  Future<List<GiftRecord>> getSent() async {
    try {
      final res = await _dio.get('/api/gifts/sent');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => GiftRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取送礼记录失败');
    }
  }
}
