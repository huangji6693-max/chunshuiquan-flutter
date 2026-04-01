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

  Future<void> updateProfile({
    required String bio,
    required String jobTitle,
    required String lookingFor,
  }) async {
    try {
      await _dio.put('/api/users/profile', data: {
        'bio': bio,
        'jobTitle': jobTitle,
        'lookingFor': lookingFor,
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

  // TODO: 后端暂无重排照片API，待后端实现后补充
  // Future<void> reorderAvatars(List<String> urls) async {
  //   await _dio.put('/api/users/avatar/reorder', data: {'urls': urls});
  // }
}
