import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  /// 更新用户资料（含扩展字段）
  Future<void> updateProfile({
    required String bio,
    required String jobTitle,
    required String lookingFor,
    int? height,
    String? education,
    String? zodiac,
    String? city,
    String? smoking,
    String? drinking,
  }) async {
    try {
      await _dio.put('/api/users/profile', data: {
        'bio': bio,
        'jobTitle': jobTitle,
        'lookingFor': lookingFor,
        if (height != null) 'height': height,
        if (education != null) 'education': education,
        if (zodiac != null) 'zodiac': zodiac,
        if (city != null) 'city': city,
        if (smoking != null) 'smoking': smoking,
        if (drinking != null) 'drinking': drinking,
      });
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '更新失败');
    }
  }

  Future<void> addAvatar(String url) async {
    try {
      await _dio.post('/api/users/avatar', data: {'url': url});
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '头像上传失败');
    }
  }

  /// 删除指定索引的头像
  Future<void> deleteAvatar(int index) async {
    try {
      await _dio.delete('/api/users/avatar/$index');
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '删除头像失败');
    }
  }

  /// 重排头像顺序
  Future<void> reorderAvatars(List<String> urls) async {
    try {
      await _dio.put('/api/users/avatar/reorder', data: {
        'avatarUrls': urls,
      });
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '重排头像失败');
    }
  }
}
