import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final momentRepositoryProvider = Provider<MomentRepository>(
  (ref) => MomentRepository(ref.watch(dioProvider)),
);

class MomentItem {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorVipTier;
  final String? content;
  final List<String> imageUrls;
  final String? location;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final DateTime createdAt;

  MomentItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorVipTier,
    this.content,
    required this.imageUrls,
    this.location,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.createdAt,
  });

  factory MomentItem.fromJson(Map<String, dynamic> json) => MomentItem(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String? ?? '用户',
        authorAvatar: json['authorAvatar'] as String?,
        authorVipTier: json['authorVipTier'] as String?,
        content: json['content'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        location: json['location'] as String?,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class CommentItem {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? replyToId;
  final String content;
  final DateTime createdAt;

  CommentItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.replyToId,
    required this.content,
    required this.createdAt,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) => CommentItem(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String? ?? '用户',
        authorAvatar: json['authorAvatar'] as String?,
        replyToId: json['replyToId'] as String?,
        content: json['content'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class MomentRepository {
  final Dio _dio;
  MomentRepository(this._dio);

  Future<List<MomentItem>> getTimeline({int page = 0}) async {
    try {
      final res = await _dio.get('/api/moments', queryParameters: {'page': page});
      final list = res.data as List<dynamic>;
      return list.map((e) => MomentItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取动态失败');
    }
  }

  Future<MomentItem> createMoment({String? content, List<String>? imageUrls, String? location}) async {
    try {
      final res = await _dio.post('/api/moments', data: {
        'content': content,
        'imageUrls': imageUrls,
        'location': location,
        'visibility': 'public',
      });
      return MomentItem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '发布失败');
    }
  }

  Future<Map<String, dynamic>> toggleLike(String momentId) async {
    try {
      final res = await _dio.post('/api/moments/$momentId/like');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '操作失败');
    }
  }

  Future<List<CommentItem>> getComments(String momentId) async {
    try {
      final res = await _dio.get('/api/moments/$momentId/comments');
      final list = res.data as List<dynamic>;
      return list.map((e) => CommentItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取评论失败');
    }
  }

  Future<CommentItem> addComment(String momentId, String content, {String? replyToId}) async {
    try {
      final res = await _dio.post('/api/moments/$momentId/comments', data: {
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,
      });
      return CommentItem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '评论失败');
    }
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      await _dio.delete('/api/moments/$momentId');
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '删除失败');
    }
  }
}
