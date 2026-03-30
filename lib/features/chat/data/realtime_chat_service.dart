import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/storage/token_manager.dart';
import 'message_repository.dart';

const _realtimeBaseUrl = String.fromEnvironment(
  'REALTIME_BASE_URL',
  defaultValue: 'wss://chunshuiquan-backend-production.up.railway.app/ws',
);

enum RealtimeConnectionState {
  connecting,
  connected,
  disconnected,
}

class RealtimeChatChannel {
  final String matchId;

  const RealtimeChatChannel(this.matchId);

  String get name => 'conversation:$matchId';

  Uri connectionUri(String token) {
    return Uri.parse(
      '$_realtimeBaseUrl/matches/$matchId?token=${Uri.encodeQueryComponent(token)}',
    );
  }
}

sealed class RealtimeChatEvent {
  const RealtimeChatEvent();
}

class RealtimeConnectionChanged extends RealtimeChatEvent {
  final RealtimeConnectionState state;

  const RealtimeConnectionChanged(this.state);
}

class RealtimeMessageReceived extends RealtimeChatEvent {
  final ChatMessage message;

  const RealtimeMessageReceived(this.message);
}

final realtimeChatServiceProvider = Provider<RealtimeChatService>((ref) {
  return RealtimeChatService(
    tokenManager: ref.watch(tokenManagerProvider),
  );
});

class RealtimeChatService {
  final TokenManager tokenManager;

  RealtimeChatService({required this.tokenManager});

  Stream<RealtimeChatEvent> subscribe(String matchId) async* {
    final token = await tokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing access token for realtime chat');
    }

    final channelDef = RealtimeChatChannel(matchId);
    final controller = StreamController<RealtimeChatEvent>();
    WebSocketChannel? channel;
    StreamSubscription? sub;

    controller.add(const RealtimeConnectionChanged(RealtimeConnectionState.connecting));

    try {
      channel = WebSocketChannel.connect(channelDef.connectionUri(token));
      controller.add(const RealtimeConnectionChanged(RealtimeConnectionState.connected));

      sub = channel.stream.listen(
        (event) {
          final payload = event is String ? jsonDecode(event) : event;
          if (payload is! Map<String, dynamic>) return;
          controller.add(
            RealtimeMessageReceived(ChatMessage.fromJson(payload)),
          );
        },
        onDone: () {
          controller.add(
            const RealtimeConnectionChanged(RealtimeConnectionState.disconnected),
          );
        },
        onError: (_) {
          controller.add(
            const RealtimeConnectionChanged(RealtimeConnectionState.disconnected),
          );
        },
        cancelOnError: false,
      );
    } catch (_) {
      await controller.close();
      rethrow;
    }

    controller.onCancel = () async {
      await sub?.cancel();
      await channel?.sink.close();
    };

    yield* controller.stream;
  }
}
