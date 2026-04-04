import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final callRepositoryProvider = Provider<CallRepository>(
  (ref) => CallRepository(ref.watch(dioProvider)),
);

class CallRepository {
  final Dio _dio;
  CallRepository(this._dio);

  Future<Map<String, dynamic>> getAgoraToken(String channelName) async {
    final res = await _dio.get(
      '/api/agora/token',
      queryParameters: {'channelName': channelName},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> sendInvite(String matchId) async {
    await _dio.post(
      '/api/agora/invite',
      queryParameters: {'matchId': matchId},
    );
  }
}
