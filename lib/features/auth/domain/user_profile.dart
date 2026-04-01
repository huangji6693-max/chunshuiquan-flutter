/// 用户资料数据模型
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? jobTitle;
  final String gender;
  final String lookingFor;
  final List<String> avatarUrls;
  final List<String> tags;
  // 扩展字段
  final int? height;        // 身高(cm)
  final String? education;  // 学历
  final String? zodiac;     // 星座
  final String? city;       // 城市
  final String? smoking;    // 吸烟习惯
  final String? drinking;   // 饮酒习惯
  final String? birthDate;  // 生日字符串，用于计算年龄

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.jobTitle,
    required this.gender,
    required this.lookingFor,
    required this.avatarUrls,
    required this.tags,
    this.height,
    this.education,
    this.zodiac,
    this.city,
    this.smoking,
    this.drinking,
    this.birthDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        bio: json['bio'] as String?,
        jobTitle: json['jobTitle'] as String?,
        gender: json['gender'] as String? ?? 'other',
        lookingFor: json['lookingFor'] as String? ?? 'everyone',
        avatarUrls: (json['avatarUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        height: json['height'] as int?,
        education: json['education'] as String?,
        zodiac: json['zodiac'] as String?,
        city: json['city'] as String?,
        smoking: json['smoking'] as String?,
        drinking: json['drinking'] as String?,
        birthDate: json['birthDate'] as String?,
      );

  String get firstAvatar => avatarUrls.isNotEmpty ? avatarUrls.first : '';

  /// 根据 birthDate 计算年龄
  int? get age {
    if (birthDate == null || birthDate!.isEmpty) return null;
    try {
      final birth = DateTime.parse(birthDate!);
      final now = DateTime.now();
      int a = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        a--;
      }
      return a;
    } catch (_) {
      return null;
    }
  }
}
