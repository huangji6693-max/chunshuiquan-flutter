import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final vipRepositoryProvider = Provider<VipRepository>(
  (ref) => VipRepository(ref.watch(dioProvider)),
);

class VipStatus {
  final String tier; // none / gold / diamond
  final DateTime? expiresAt;
  final int daysLeft;
  final bool isActive;

  VipStatus({
    required this.tier,
    this.expiresAt,
    required this.daysLeft,
    required this.isActive,
  });

  factory VipStatus.fromJson(Map<String, dynamic> json) {
    return VipStatus(
      tier: json['tier'] as String? ?? 'none',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      daysLeft: json['daysLeft'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  bool get isGold => tier == 'gold' && isActive;
  bool get isDiamond => tier == 'diamond' && isActive;
  bool get isVip => isActive && tier != 'none';
}

class VipPlan {
  final String id;
  final String tier;
  final String label;
  final String price;
  final String? originalPrice;
  final int days;
  final bool isBestValue;

  const VipPlan({
    required this.id,
    required this.tier,
    required this.label,
    required this.price,
    this.originalPrice,
    required this.days,
    this.isBestValue = false,
  });
}

class VipRepository {
  final Dio _dio;
  VipRepository(this._dio);

  static const goldPlans = [
    VipPlan(id: 'gold_monthly', tier: 'gold', label: '1个月', price: '¥28', days: 30),
    VipPlan(id: 'gold_quarterly', tier: 'gold', label: '3个月', price: '¥68', originalPrice: '¥84', days: 90, isBestValue: true),
    VipPlan(id: 'gold_yearly', tier: 'gold', label: '12个月', price: '¥198', originalPrice: '¥336', days: 365),
  ];

  static const diamondPlans = [
    VipPlan(id: 'diamond_monthly', tier: 'diamond', label: '1个月', price: '¥48', days: 30),
    VipPlan(id: 'diamond_quarterly', tier: 'diamond', label: '3个月', price: '¥118', originalPrice: '¥144', days: 90, isBestValue: true),
    VipPlan(id: 'diamond_yearly', tier: 'diamond', label: '12个月', price: '¥368', originalPrice: '¥576', days: 365),
  ];

  Future<VipStatus> getStatus() async {
    try {
      final res = await _dio.get('/api/vip/status');
      return VipStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取VIP状态失败');
    }
  }

  Future<VipStatus> subscribe(String planId, {String? receipt, String? platform}) async {
    try {
      final res = await _dio.post('/api/vip/subscribe', data: {
        'planId': planId,
        'receipt': receipt ?? 'demo_${DateTime.now().millisecondsSinceEpoch}',
        'platform': platform ?? 'apple',
      });
      return VipStatus.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '订阅失败');
    }
  }
}
