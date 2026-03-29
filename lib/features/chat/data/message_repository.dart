import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(ref.watch(dioProvider)),
);

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        senderId: json['senderId'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
}

class MessageRepository {
  final Dio _dio;
  MessageRepository(this._dio);

  Future<List<ChatMessage>> fetchMessages(String matchId, {int page = 0, int size = 20}) async {
    try {
      final res = await _dio.get('/api/matches/$matchId/messages',
          queryParameters: {'page': page, 'size': size});
      final data = res.data as Map<String, dynamic>;
      final list = data['content'] as List<dynamic>;
      return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取消息失败');
    }
  }

  Future<ChatMessage> sendMessage(String matchId, String content) async {
    try {
      final res = await _dio.post('/api/matches/$matchId/messages',
          data: {'content': content});
      return ChatMessage.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '发送失败');
    }
  }
}
