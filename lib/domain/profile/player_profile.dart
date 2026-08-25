import 'rank_tier.dart';

final class PlayerProfile {
  final String id;
  final String username;
  final String displayName;
  final String avatarId;
  final String? avatarUrl;
  final int mmr;
  final int provisionalMatchesRemaining;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int reactionAverage;
  final int memoryAverage;
  final int precisionAverage;

  const PlayerProfile({
    required this.id,
    required this.username,
    String? displayName,
    this.avatarId = 'avatar_01',
    this.avatarUrl,
    this.mmr = 1000,
    this.provisionalMatchesRemaining = 10,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.reactionAverage = 0,
    this.memoryAverage = 0,
    this.precisionAverage = 0,
  }) : displayName = displayName ?? username;

  RankTier get rankTier => RankTier.fromMmr(mmr);
  String get rankDivision => rankTier.divisionString(mmr);

  double get winRate =>
      matchesPlayed == 0 ? 0.0 : (wins / matchesPlayed) * 100.0;

  bool get isProvisional => provisionalMatchesRemaining > 0;

  String get strongestSkill {
    if (reactionAverage == 0 && memoryAverage == 0 && precisionAverage == 0) {
      return 'CALIBRATING';
    }
    if (reactionAverage >= memoryAverage &&
        reactionAverage >= precisionAverage) {
      return 'REACTION';
    }
    if (memoryAverage >= precisionAverage) {
      return 'MEMORY';
    }
    return 'PRECISION';
  }

  String get weakSkill {
    if (reactionAverage == 0 && memoryAverage == 0 && precisionAverage == 0) {
      return 'CALIBRATING';
    }
    if (reactionAverage <= memoryAverage &&
        reactionAverage <= precisionAverage) {
      return 'REACTION';
    }
    if (memoryAverage <= precisionAverage) {
      return 'MEMORY';
    }
    return 'PRECISION';
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? 'Challenger';
    return PlayerProfile(
      id: json['id'] as String? ?? '',
      username: username,
      displayName: json['display_name'] as String? ?? username,
      avatarId: json['avatar_id'] as String? ?? 'avatar_01',
      avatarUrl: json['avatar_url'] as String?,
      mmr: (json['mmr'] as num?)?.toInt() ?? 1000,
      provisionalMatchesRemaining:
          (json['provisional_matches_remaining'] as num?)?.toInt() ?? 10,
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      reactionAverage: (json['reaction_average'] as num?)?.toInt() ?? 0,
      memoryAverage: (json['memory_average'] as num?)?.toInt() ?? 0,
      precisionAverage: (json['precision_average'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_id': avatarId,
        'avatar_url': avatarUrl,
        'mmr': mmr,
        'provisional_matches_remaining': provisionalMatchesRemaining,
        'matches_played': matchesPlayed,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'reaction_average': reactionAverage,
        'memory_average': memoryAverage,
        'precision_average': precisionAverage,
      };

  PlayerProfile copyWith({
    String? displayName,
    String? avatarId,
    String? avatarUrl,
    int? mmr,
    int? provisionalMatchesRemaining,
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? draws,
    int? reactionAverage,
    int? memoryAverage,
    int? precisionAverage,
  }) {
    return PlayerProfile(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mmr: mmr ?? this.mmr,
      provisionalMatchesRemaining:
          provisionalMatchesRemaining ?? this.provisionalMatchesRemaining,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      reactionAverage: reactionAverage ?? this.reactionAverage,
      memoryAverage: memoryAverage ?? this.memoryAverage,
      precisionAverage: precisionAverage ?? this.precisionAverage,
    );
  }
}
