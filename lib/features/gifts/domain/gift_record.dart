/// 礼物记录模型（对齐后端 GiftRecordDto）
class GiftRecord {
  final String id;
  final String senderId;
  final String? senderName;
  final String receiverId;
  final String? receiverName;
  final int? giftId;
  final String? giftName;
  final String? giftIcon;
  final int? giftCoins;
  final String? matchId;
  final DateTime? createdAt;

  const GiftRecord({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.receiverId,
    this.receiverName,
    this.giftId,
    this.giftName,
    this.giftIcon,
    this.giftCoins,
    this.matchId,
    this.createdAt,
  });

  factory GiftRecord.fromJson(Map<String, dynamic> json) => GiftRecord(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String?,
        receiverId: json['receiverId'] as String,
        receiverName: json['receiverName'] as String?,
        giftId: json['giftId'] as int?,
        giftName: json['giftName'] as String?,
        giftIcon: json['giftIcon'] as String?,
        giftCoins: json['giftCoins'] as int?,
        matchId: json['matchId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
