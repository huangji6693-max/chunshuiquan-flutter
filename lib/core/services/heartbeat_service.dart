import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

/// 心跳服务：每30秒向后端发送心跳，维护在线状态
/// App进入前台时启动，进入后台时停止
class HeartbeatService with WidgetsBindingObserver {
  final Dio _dio;
  Timer? _timer;
  bool _active = false;

  HeartbeatService(this._dio);

  /// 启动心跳
  void start() {
    if (_active) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);
    _sendHeartbeat();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
  }

  /// 停止心跳
  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// 发送心跳请求
  Future<void> _sendHeartbeat() async {
    try {
      await _dio.post('/api/users/heartbeat');
    } catch (_) {
      // 心跳失败静默处理
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App回到前台，重新启动心跳
      _timer?.cancel();
      _sendHeartbeat();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
    } else if (state == AppLifecycleState.paused) {
      // App进入后台，停止心跳
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    stop();
  }
}

/// 心跳服务 Provider
final heartbeatServiceProvider = Provider<HeartbeatService>((ref) {
  final dio = ref.watch(dioProvider);
  final service = HeartbeatService(dio);
  ref.onDispose(() => service.dispose());
  return service;
});

/// 在线状态 Provider：获取指定用户的在线状态
final onlineStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/users/$userId/online');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data['online'] as bool? ?? false;
    }
    return false;
  } catch (_) {
    return false;
  }
});
