import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_manager.dart';
import 'message_repository.dart';

const _realtimeBaseUrl = String.fromEnvironment(
  'REALTIME_BASE_URL',
  defaultValue: 'wss://chunshuiquan-backend-production.up.railway.app/ws',
);

final realtimeChatServiceProvider = Provider<RealtimeChatService>((ref) {
  return RealtimeChatService(
    tokenManager: ref.watch(tokenManagerProvider),
  );
});

class RealtimeChatEvent {
  final ChatMessage message;

  const RealtimeChatEvent(this.message);
}

class RealtimeChatService {
  final TokenManager tokenManager;

  RealtimeChatService({required this.tokenManager});

  Stream<RealtimeChatEvent> subscribe(String matchId) async* {
    final token = await tokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing access token for realtime chat');
    }

    final uri = Uri.parse(
      '$_realtimeBaseUrl/matches/$matchId?token=${Uri.encodeQueryComponent(token)}',
    );

    final channel = WebSocketChannel.connect(uri);
    yield* channel.stream.map((event) {
      final payload = event is String ? jsonDecode(event) : event;
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Unexpected realtime payload');
      }
      return RealtimeChatEvent(ChatMessage.fromJson(payload));
    }).asBroadcastStream(onCancel: (sub) async {
      await sub.cancel();
      await channel.sink.close();
    });
  }
}
