final class DailyLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int totalScore;
  final bool isCurrentUser;

  const DailyLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.totalScore,
    this.isCurrentUser = false,
  });

  factory DailyLeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final uid = json['user_id'] as String? ?? '';
    return DailyLeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: uid,
      username: json['username'] as String? ?? 'Player',
      displayName: json['display_name'] as String? ?? json['username'] as String? ?? 'Player',
      avatarUrl: json['avatar_url'] as String?,
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? (currentUserId != null && uid == currentUserId),
    );
  }
}
