import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final likesRepositoryProvider = Provider<LikesRepository>(
  (ref) => LikesRepository(ref.watch(dioProvider)),
);

class LikeItem {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final int? age;
  final String? city;
  final bool blurred;
  final String direction; // RIGHT or UP (super like)

  LikeItem({
    required this.userId,
    this.name,
    this.avatarUrl,
    this.age,
    this.city,
    required this.blurred,
    required this.direction,
  });

  factory LikeItem.fromJson(Map<String, dynamic> json) {
    return LikeItem(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      age: json['age'] as int?,
      city: json['city'] as String?,
      blurred: json['blurred'] as bool? ?? true,
      direction: json['direction'] as String? ?? 'RIGHT',
    );
  }
}

class LikesResult {
  final bool isVip;
  final int count;
  final List<LikeItem> likes;

  LikesResult({required this.isVip, required this.count, required this.likes});

  factory LikesResult.fromJson(Map<String, dynamic> json) {
    return LikesResult(
      isVip: json['isVip'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      likes: (json['likes'] as List<dynamic>?)
              ?.map((e) => LikeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LikesRepository {
  final Dio _dio;
  LikesRepository(this._dio);

  Future<int> getLikesCount() async {
    try {
      final res = await _dio.get('/api/likes/count');
      return (res.data as Map<String, dynamic>)['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取喜欢数失败');
    }
  }

  Future<LikesResult> getWhoLikesMe() async {
    try {
      final res = await _dio.get('/api/likes');
      return LikesResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取喜欢列表失败');
    }
  }
}
