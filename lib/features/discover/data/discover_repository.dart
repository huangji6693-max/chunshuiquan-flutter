import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/user_profile.dart';
import '../domain/swipe_result.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref.watch(dioProvider)),
);

class DiscoverRepository {
  final Dio _dio;
  DiscoverRepository(this._dio);

  /// 获取推荐列表，支持筛选参数
  Future<List<UserProfile>> fetchFeed({
    int? minAge,
    int? maxAge,
    String? gender,
    double? maxDistance,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (minAge != null) queryParams['minAge'] = minAge;
      if (maxAge != null) queryParams['maxAge'] = maxAge;
      if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance;

      final res = await _dio.get('/api/users/feed', queryParameters: queryParams);
      final list = res.data as List<dynamic>;
      return list.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取推荐列表失败');
    }
  }

  /// 获取附近的人
  Future<List<UserProfile>> getNearby({double radiusKm = 50, int size = 50}) async {
    try {
      final res = await _dio.get('/api/users/nearby', queryParameters: {
        'radiusKm': radiusKm,
        'size': size,
      });
      final list = res.data as List<dynamic>;
      return list.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取附近用户失败');
    }
  }

  Future<SwipeResult> sendSwipe(String userId, String direction) async {
    try {
      final res = await _dio.post('/api/swipe', data: {
        'swipedId': userId,
        'direction': direction,
      });
      final data = res.data;
      if (data is Map<String, dynamic>) return SwipeResult.fromJson(data);
      return SwipeResult.noMatch;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '滑动失败');
    }
  }
}
