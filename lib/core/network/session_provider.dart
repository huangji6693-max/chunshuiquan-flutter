import 'package:flutter_riverpod/flutter_riverpod.dart';

// Session 过期回调 Provider，由 ProviderScope overrides 注入
final sessionExpiredCallbackProvider =
    Provider<Future<void> Function()>((ref) {
  // 默认抛出，强制外部 override
  throw UnimplementedError('sessionExpiredCallbackProvider must be overridden');
});
