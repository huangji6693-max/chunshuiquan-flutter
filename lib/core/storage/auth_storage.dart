import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_manager.dart';

// 向后兼容代理层
final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(ref.watch(tokenManagerProvider));
});

class AuthStorage {
  final TokenManager _tm;
  AuthStorage(this._tm);

  Future<String?> getToken() => _tm.getAccessToken();
  Future<void> deleteToken() => _tm.clearTokens();
}
