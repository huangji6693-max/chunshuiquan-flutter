class SwipeResult {
  final bool matched;
  final String? matchId;
  final String? partnerName;
  final String? partnerAvatarUrl;

  const SwipeResult({
    required this.matched,
    this.matchId,
    this.partnerName,
    this.partnerAvatarUrl,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) => SwipeResult(
        matched: json['matched'] as bool? ?? false,
        matchId: json['matchId'] as String?,
        partnerName: json['partnerName'] as String?,
        partnerAvatarUrl: json['partnerAvatarUrl'] as String?,
      );

  static const noMatch = SwipeResult(matched: false);
}
