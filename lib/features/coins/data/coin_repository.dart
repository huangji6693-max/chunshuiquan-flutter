import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

final coinRepositoryProvider = Provider<CoinRepository>(
  (ref) => CoinRepository(ref.watch(dioProvider)),
);

class CoinPackage {
  final String id;
  final int coins;
  final String label;
  final String price;
  final bool isPopular;

  const CoinPackage({
    required this.id,
    required this.coins,
    required this.label,
    required this.price,
    this.isPopular = false,
  });
}

class CoinTransaction {
  final String id;
  final int amount;
  final int balanceAfter;
  final String type;
  final String? note;
  final DateTime createdAt;

  CoinTransaction({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    this.note,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      type: json['type'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CoinRepository {
  final Dio _dio;
  CoinRepository(this._dio);

  static const packages = [
    CoinPackage(id: 'small', coins: 60, label: '60金币', price: '¥6'),
    CoinPackage(id: 'medium', coins: 300, label: '300金币', price: '¥25', isPopular: true),
    CoinPackage(id: 'large', coins: 980, label: '980金币', price: '¥68'),
    CoinPackage(id: 'mega', coins: 2000, label: '2000金币', price: '¥128'),
  ];

  Future<int> getBalance() async {
    try {
      final res = await _dio.get('/api/coins/balance');
      return (res.data as Map<String, dynamic>)['coins'] as int;
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取余额失败');
    }
  }

  Future<CoinTransaction> recharge(String packageId, {String? receipt, String? platform}) async {
    try {
      final res = await _dio.post('/api/coins/recharge', data: {
        'packageId': packageId,
        'receipt': receipt ?? 'demo_receipt_${DateTime.now().millisecondsSinceEpoch}',
        'platform': platform ?? 'apple',
      });
      return CoinTransaction.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '充值失败');
    }
  }

  Future<List<CoinTransaction>> getTransactions() async {
    try {
      final res = await _dio.get('/api/coins/transactions');
      final list = res.data as List<dynamic>;
      return list.map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.network(e.message ?? '获取流水失败');
    }
  }
}
