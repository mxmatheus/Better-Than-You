import 'rank_tier.dart';

final class PlayerProfile {
  final String id;
  final String username;
  final String avatarId;
  final int mmr;
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
    this.avatarId = 'avatar_01',
    this.mmr = 1000,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.reactionAverage = 0,
    this.memoryAverage = 0,
    this.precisionAverage = 0,
  });

  RankTier get rankTier => RankTier.fromMmr(mmr);
  String get rankDivision => rankTier.divisionString(mmr);

  double get winRate =>
      matchesPlayed == 0 ? 0.0 : (wins / matchesPlayed) * 100.0;

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
}
