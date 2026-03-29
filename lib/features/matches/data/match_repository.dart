import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(dioProvider)),
);

class MatchItem {
  final String matchId;
  final String otherId;
  final String otherName;
  final String? otherAvatarUrl;
  final String? otherBio;
  final DateTime createdAt;
  final bool? isNew;

  MatchItem({
    required this.matchId,
    required this.otherId,
    required this.otherName,
    this.otherAvatarUrl,
    this.otherBio,
    required this.createdAt,
    this.isNew,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final other = json['otherUser'] as Map<String, dynamic>? ?? {};
    final avatarUrls = other['avatarUrls'] as List<dynamic>?;
    return MatchItem(
      matchId: json['matchId'] as String,
      otherId: other['id'] as String? ?? '',
      otherName: other['name'] as String? ?? '用户',
      otherAvatarUrl: avatarUrls != null && avatarUrls.isNotEmpty ? avatarUrls.first as String : null,
      otherBio: other['bio'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isNew: json['isNew'] as bool?,
    );
  }
}

class MatchRepository {
  final Dio _dio;
  MatchRepository(this._dio);

  Future<List<MatchItem>> fetchMatches() async {
    try {
      final res = await _dio.get('/api/matches');
      final list = res.data as List<dynamic>;
      return list.map((e) => MatchItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取匹配列表失败');
    }
  }
}
