import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/user_profile.dart';
import '../../auth/domain/user_profile.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref.watch(dioProvider)),
);

class DiscoverRepository {
  final Dio _dio;
  DiscoverRepository(this._dio);

  Future<List<UserProfile>> fetchFeed() async {
    try {
      final res = await _dio.get('/api/users/feed');
      final list = res.data as List<dynamic>;
      return list.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取推荐列表失败');
    }
  }

  Future<void> sendSwipe(String userId, String direction) async {
    try {
      await _dio.post('/api/swipe', data: {
        'swipedId': userId,
        'direction': direction,
      });
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '滑动失败');
    }
  }
}
