import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepository(ref.watch(dioProvider)),
);

class UploadRepository {
  final Dio _dio;
  UploadRepository(this._dio);

  /// 从 Cloudinary URL 解析 publicId
  static String? extractPublicId(String url) {
    const marker = '/upload/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    String path = url.substring(idx + marker.length);
    path = path.replaceFirst(RegExp(r'^v\d+/'), '');
    return path.replaceFirst(RegExp(r'\.[^.]+$'), '');
  }

  /// 从后端获取 Cloudinary 签名
  Future<Map<String, dynamic>> _getSignature() async {
    try {
      final res = await _dio.post('/api/upload/signature');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取上传签名失败');
    }
  }

  /// 上传图片到 Cloudinary，返回 secure_url
  Future<String> uploadImage(File imageFile) async {
    final sig = await _getSignature();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'api_key': sig['apiKey'],
      'timestamp': sig['timestamp'],
      'signature': sig['signature'],
    });

    try {
      final res = await Dio().post(
        'https://api.cloudinary.com/v1_1/${sig['cloudName']}/image/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return res.data['secure_url'] as String;
    } on DioException catch (e) {
      throw AppException.network('图片上传失败: ${e.message}');
    }
  }

  /// 上传头像并保存 URL 到后端
  Future<String> uploadAvatar(File imageFile) async {
    final url = await uploadImage(imageFile);
    try {
      await _dio.post('/api/users/avatar', data: {'url': url});
    } on DioException catch (e) {
      throw AppException.network('保存头像失败: ${e.message}');
    }
    return url;
  }

  /// 从相册选图并上传
  Future<String?> pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return uploadAvatar(File(picked.path));
  }
}
