import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepository(ref.watch(dioProvider)),
);

class CheckInStatus {
  final bool checkedInToday;
  final int streakDays;
  final int todayReward;
  final int totalCoins;
  final List<bool> weekStatus; // 周一到周日

  CheckInStatus({
    required this.checkedInToday,
    required this.streakDays,
    required this.todayReward,
    required this.totalCoins,
    required this.weekStatus,
  });

  factory CheckInStatus.fromJson(Map<String, dynamic> json) {
    return CheckInStatus(
      checkedInToday: json['checkedInToday'] as bool? ?? false,
      streakDays: json['streakDays'] as int? ?? 0,
      todayReward: json['todayReward'] as int? ?? 10,
      totalCoins: json['totalCoins'] as int? ?? 0,
      weekStatus: (json['weekStatus'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(7, false),
    );
  }
}

class CheckInRepository {
  final Dio _dio;
  CheckInRepository(this._dio);

  Future<CheckInStatus> getStatus() async {
    try {
      final res = await _dio.get('/api/checkin/status');
      return CheckInStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取签到状态失败');
    }
  }

  Future<CheckInStatus> checkIn() async {
    try {
      final res = await _dio.post('/api/checkin');
      return CheckInStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '签到失败');
    }
  }
}
