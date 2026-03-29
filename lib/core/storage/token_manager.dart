import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenManagerProvider = Provider<TokenManager>((_) => TokenManager());

class TokenManager {
  static const _kAccess  = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _storage  = FlutterSecureStorage();

  Future<String?> getAccessToken()  => _storage.read(key: _kAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      Future.wait([
        _storage.write(key: _kAccess,  value: accessToken),
        _storage.write(key: _kRefresh, value: refreshToken),
      ]);

  Future<void> clearTokens() => Future.wait([
        _storage.delete(key: _kAccess),
        _storage.delete(key: _kRefresh),
      ]);

  Future<String?> getToken() => getAccessToken();
  Future<void> deleteToken() => clearTokens();
}
