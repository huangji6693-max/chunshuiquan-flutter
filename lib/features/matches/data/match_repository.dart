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
  final List<String> otherAvatarUrls;
  final String? otherBio;
  final String? otherJobTitle;
  final String? otherCity;
  final int? otherHeight;
  final String? otherEducation;
  final String? otherZodiac;
  final String? otherVipTier;
  final DateTime createdAt;
  final bool? isNew;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  MatchItem({
    required this.matchId,
    required this.otherId,
    required this.otherName,
    this.otherAvatarUrl,
    this.otherAvatarUrls = const [],
    this.otherBio,
    this.otherJobTitle,
    this.otherCity,
    this.otherHeight,
    this.otherEducation,
    this.otherZodiac,
    this.otherVipTier,
    required this.createdAt,
    this.isNew,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final other = json['otherUser'] as Map<String, dynamic>? ?? {};
    final avatarUrls = (other['avatarUrls'] as List<dynamic>?)
        ?.map((e) => e as String).toList() ?? [];
    return MatchItem(
      matchId: json['matchId'] as String,
      otherId: other['id'] as String? ?? '',
      otherName: other['name'] as String? ?? '用户',
      otherAvatarUrl: avatarUrls.isNotEmpty ? avatarUrls.first : null,
      otherAvatarUrls: avatarUrls,
      otherBio: other['bio'] as String?,
      otherJobTitle: other['jobTitle'] as String?,
      otherCity: other['city'] as String?,
      otherHeight: other['height'] as int?,
      otherEducation: other['education'] as String?,
      otherZodiac: other['zodiac'] as String?,
      otherVipTier: other['vipTier'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isNew: (json['isNew'] ?? json['new']) as bool?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
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
