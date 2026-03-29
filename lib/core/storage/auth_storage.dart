import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_manager.dart';

// 向后兼容：auth_storage 直接代理 token_manager
final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(ref.watch(tokenManagerProvider));
});

class AuthStorage {
  final TokenManager _tm;
  AuthStorage(this._tm);

  Future<String?> getToken() => _tm.getAccessToken();
  Future<void> saveToken(String token) => _tm.saveToken(token);
  Future<void> deleteToken() => _tm.clearTokens();
}
