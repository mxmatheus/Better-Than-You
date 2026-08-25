import '../challenge/challenge_type.dart';

final class DailyChallenge {
  final DateTime challengeDate;
  final int seed;
  final List<ChallengeType> scheduledChallenges;
  final int totalRounds;

  const DailyChallenge({
    required this.challengeDate,
    required this.seed,
    required this.scheduledChallenges,
    this.totalRounds = 10,
  });

  /// Derive deterministic 32-bit positive integer seed from UTC date
  static int deriveSeedForDate(DateTime utcDate) {
    final dateInt = utcDate.year * 10000 + utcDate.month * 100 + utcDate.day;
    return ((dateInt * 1664525) + 1013904223) & 0xFFFFFFFF;
  }
}
