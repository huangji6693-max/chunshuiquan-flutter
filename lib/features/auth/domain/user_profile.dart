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
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      );

  String get firstAvatar => avatarUrls.isNotEmpty ? avatarUrls.first : '';
}
