/// 礼物模型
class Gift {
  final int id;
  final String name;
  final String icon; // emoji
  final int coins;

  const Gift({
    required this.id,
    required this.name,
    required this.icon,
    required this.coins,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => Gift(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        icon: json['icon'] as String,
        coins: (json['coins'] as num).toInt(),
      );
}
