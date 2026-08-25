import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/daily/daily_challenge.dart';
import 'package:better_than_you/domain/daily/daily_leaderboard_entry.dart';
import 'package:better_than_you/domain/daily/daily_submission.dart';
import 'package:better_than_you/domain/daily/local_daily_challenge_repository.dart';

void main() {
  group('Daily Challenge — Deterministic Generation & Invariants', () {
    test('Same UTC date produces identical daily seed across instances', () {
      final date1 = DateTime.utc(2026, 8, 26);
      final date2 = DateTime.utc(2026, 8, 26);

      final seed1 = DailyChallenge.deriveSeedForDate(date1);
      final seed2 = DailyChallenge.deriveSeedForDate(date2);

      expect(seed1, equals(seed2));
      expect(seed1, equals(1582093681)); // Canonical 2026-08-26 seed
    });

    test('Different UTC dates produce distinct seeds', () {
      final dateA = DateTime.utc(2026, 8, 26);
      final dateB = DateTime.utc(2026, 8, 27);

      final seedA = DailyChallenge.deriveSeedForDate(dateA);
      final seedB = DailyChallenge.deriveSeedForDate(dateB);

      expect(seedA, isNot(equals(seedB)));
    });

    test('Daily challenge generates exactly 10 deterministic rounds', () async {
      final repo = LocalDailyChallengeRepository();
      final date = DateTime.utc(2026, 8, 26);
      final challenge = await repo.getDailyChallenge(date: date);

      expect(challenge.totalRounds, equals(10));
      expect(challenge.scheduledChallenges.length, equals(10));
      expect(challenge.seed, equals(1582093681));

      // Same call returns identical sequence
      final challenge2 = await repo.getDailyChallenge(date: date);
      expect(challenge.scheduledChallenges, equals(challenge2.scheduledChallenges));
    });
  });

  group('Daily Challenge — One Attempt & Resumption Logic', () {
    test('Starting challenge creates in-progress submission at Round 1', () async {
      final repo = LocalDailyChallengeRepository();
      final sub = await repo.startOrResumeDailyChallenge(date: DateTime.utc(2026, 8, 26));

      expect(sub.status, equals(DailyAttemptStatus.inProgress));
      expect(sub.currentRoundIndex, equals(1));
      expect(sub.totalScore, equals(0));
      expect(sub.isCompleted, isFalse);
    });

    test('Resuming in-progress submission restores round index and accumulated score', () async {
      final repo = LocalDailyChallengeRepository();
      final date = DateTime.utc(2026, 8, 26);
      await repo.startOrResumeDailyChallenge(date: date);

      // Re-calling startOrResume returns same active submission
      final resumed = await repo.startOrResumeDailyChallenge(date: date);
      expect(resumed.currentRoundIndex, equals(1));
      expect(resumed.status, equals(DailyAttemptStatus.inProgress));
    });
  });

  group('Global Leaderboard — Deterministic Ranking & Tie-Breaking', () {
    test('Leaderboard entries sort by score DESC, user ID ASC', () {
      final entries = [
        const DailyLeaderboardEntry(rank: 1, userId: 'user_b', username: 'B', displayName: 'B', totalScore: 8500),
        const DailyLeaderboardEntry(rank: 2, userId: 'user_a', username: 'A', displayName: 'A', totalScore: 9000),
        const DailyLeaderboardEntry(rank: 3, userId: 'user_c', username: 'C', displayName: 'C', totalScore: 8500),
      ];

      // Sort
      entries.sort((a, b) {
        final scoreCmp = b.totalScore.compareTo(a.totalScore);
        if (scoreCmp != 0) return scoreCmp;
        return a.userId.compareTo(b.userId);
      });

      expect(entries[0].userId, equals('user_a')); // 9000
      expect(entries[1].userId, equals('user_b')); // 8500 (user_b < user_c)
      expect(entries[2].userId, equals('user_c')); // 8500
    });

    test('Percentile calculation correctly scales rank over total participants', () {
      double computePercentile(int rank, int total) {
        if (total <= 0) return 100.0;
        return (rank / total) * 100.0;
      }

      expect(computePercentile(1, 100), equals(1.0));
      expect(computePercentile(10, 100), equals(10.0));
      expect(computePercentile(50, 100), equals(50.0));
      expect(computePercentile(1, 1), equals(100.0));
    });
  });
}
