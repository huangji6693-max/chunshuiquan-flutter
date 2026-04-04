import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/token_manager.dart';

/// WebSocket STOMP 服务
/// 用于实时接收聊天消息和已读回执
/// 当前版本搭建了连接框架，后续可集成完整 STOMP 协议
class WebSocketService {
  final TokenManager _tokenManager;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  bool _disposed = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  static const _baseReconnectDelay = Duration(seconds: 2);

  // 消息回调
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();

  /// 新消息流
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  /// 已读回执流
  Stream<Map<String, dynamic>> get onReadReceipt => _readReceiptController.stream;

  bool get isConnected => _isConnected;

  WebSocketService(this._tokenManager);

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _tokenManager.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final uri = Uri.parse(
        'wss://chunshuiquan-backend-production.up.railway.app/ws',
      );
      _channel = WebSocketChannel.connect(uri);

      // 发送 STOMP CONNECT 帧
      final connectFrame = 'CONNECT\n'
          'accept-version:1.2\n'
          'Authorization:Bearer $token\n'
          'heart-beat:10000,10000\n'
          '\n'
          '\x00';
      _channel!.sink.add(connectFrame);

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0; // 连接成功，重置计数

      // STOMP 心跳保活
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) {
          if (_isConnected) {
            _channel?.sink.add('\n');
          }
        },
      );
    } catch (e) {
      // WebSocket连接失败，重连机制会处理
      _isConnected = false;
    }
  }

  /// 订阅指定 match 的聊天频道
  void subscribeChatChannel(String matchId) {
    if (!_isConnected || _channel == null) return;

    // 订阅消息频道
    final subFrame = 'SUBSCRIBE\n'
        'id:sub-chat-$matchId\n'
        'destination:/topic/chat/$matchId\n'
        '\n'
        '\x00';
    _channel?.sink.add(subFrame);

    // 订阅已读回执频道
    final readSubFrame = 'SUBSCRIBE\n'
        'id:sub-read-$matchId\n'
        'destination:/topic/chat/$matchId/read\n'
        '\n'
        '\x00';
    _channel?.sink.add(readSubFrame);
  }

  /// 取消订阅指定 match 的聊天频道
  void unsubscribeChatChannel(String matchId) {
    if (!_isConnected || _channel == null) return;

    final unsubFrame = 'UNSUBSCRIBE\n'
        'id:sub-chat-$matchId\n'
        '\n'
        '\x00';
    _channel?.sink.add(unsubFrame);

    final readUnsubFrame = 'UNSUBSCRIBE\n'
        'id:sub-read-$matchId\n'
        '\n'
        '\x00';
    _channel?.sink.add(readUnsubFrame);
  }

  /// 解析 STOMP 帧数据
  void _onData(dynamic data) {
    if (data is! String) return;

    // 心跳帧
    if (data.trim().isEmpty) return;

    // 解析 STOMP 帧
    final lines = data.split('\n');
    if (lines.isEmpty) return;

    final command = lines.first.trim();
    if (command == 'CONNECTED') {
      // 连接成功
      return;
    }

    if (command == 'MESSAGE') {
      // 提取 destination 和 body
      String? destination;
      int bodyStart = -1;
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].startsWith('destination:')) {
          destination = lines[i].substring('destination:'.length).trim();
        }
        if (lines[i].trim().isEmpty) {
          bodyStart = i + 1;
          break;
        }
      }

      if (bodyStart > 0 && bodyStart < lines.length) {
        final body = lines.sublist(bodyStart).join('\n').replaceAll('\x00', '').trim();
        if (body.isNotEmpty) {
          try {
            final json = jsonDecode(body) as Map<String, dynamic>;
            if (destination != null && destination.contains('/read')) {
              _readReceiptController.add(json);
            } else {
              _messageController.add(json);
            }
          } catch (e) {
            // STOMP MESSAGE body 解析失败，非法JSON静默跳过
          }
        }
      }
    }
  }

  void _onError(dynamic error) {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  /// 指数退避重连：2s → 4s → 8s → 16s → 32s → ...最大60s，最多10次
  void _scheduleReconnect() {
    if (_disposed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectTimer?.cancel();
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts);
    final capped = delay > const Duration(seconds: 60)
        ? const Duration(seconds: 60)
        : delay;
    _reconnectAttempts++;
    _reconnectTimer = Timer(capped, connect);
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_isConnected && _channel != null) {
      final disconnectFrame = 'DISCONNECT\n'
          'receipt:disc-1\n'
          '\n'
          '\x00';
      try {
        _channel?.sink.add(disconnectFrame);
      } catch (_) {
        // disconnect时网络可能已断开，静默处理
      }
    }

    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
    _readReceiptController.close();
  }
}

/// WebSocket 服务 Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  final service = WebSocketService(tokenManager);
  ref.onDispose(() => service.dispose());
  return service;
});
