import 'daily_leaderboard_entry.dart';

final class DailyUserRankSummary {
  final bool hasCompleted;
  final DateTime challengeDate;
  final int todayScore;
  final int globalRank;
  final int totalParticipants;
  final double percentile;
  final List<DailyLeaderboardEntry> nearbyPlayers;
  final Duration durationUntilNextChallenge;

  const DailyUserRankSummary({
    required this.hasCompleted,
    required this.challengeDate,
    required this.todayScore,
    required this.globalRank,
    required this.totalParticipants,
    required this.percentile,
    required this.nearbyPlayers,
    required this.durationUntilNextChallenge,
  });

  factory DailyUserRankSummary.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final hasCompleted = json['has_completed'] as bool? ?? false;
    final dateStr = json['challenge_date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now().toUtc();
    final msUntil = (json['ms_until_next_challenge'] as num?)?.toInt() ?? 0;

    final nearbyList = (json['nearby_players'] as List<dynamic>?)
            ?.map((e) => DailyLeaderboardEntry.fromJson(
                  e as Map<String, dynamic>,
                  currentUserId: currentUserId,
                ))
            .toList() ??
        const [];

    return DailyUserRankSummary(
      hasCompleted: hasCompleted,
      challengeDate: date,
      todayScore: (json['today_score'] as num?)?.toInt() ?? 0,
      globalRank: (json['global_rank'] as num?)?.toInt() ?? 0,
      totalParticipants: (json['total_participants'] as num?)?.toInt() ?? 0,
      percentile: (json['percentile'] as num?)?.toDouble() ?? 100.0,
      nearbyPlayers: nearbyList,
      durationUntilNextChallenge: Duration(milliseconds: msUntil),
    );
  }
}
