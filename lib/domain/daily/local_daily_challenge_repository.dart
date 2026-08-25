import 'dart:math' as math;
import '../../core/utils/mulberry32.dart';
import '../challenge/challenge_evidence.dart';
import '../challenge/challenge_registry.dart';
import '../challenge/challenge_result.dart';
import '../challenge/challenge_type.dart';
import 'daily_challenge.dart';
import 'daily_challenge_repository.dart';
import 'daily_leaderboard_entry.dart';
import 'daily_submission.dart';
import 'daily_user_rank_summary.dart';

final class LocalDailyChallengeRepository implements DailyChallengeRepository {
  DailySubmission? _activeSubmission;

  @override
  Future<DailyChallenge> getDailyChallenge({DateTime? date}) async {
    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
    final seed = DailyChallenge.deriveSeedForDate(utcDate);
    final prng = Mulberry32(seed);

    final scheduled = <ChallengeType>[];
    const types = [
      ChallengeType.reaction,
      ChallengeType.precision,
      ChallengeType.memory,
    ];

    for (var i = 0; i < 10; i++) {
      final idx = prng.nextInt(0, 2);
      scheduled.add(types[idx]);
    }

    return DailyChallenge(
      challengeDate: utcDate,
      seed: seed,
      scheduledChallenges: scheduled,
      totalRounds: 10,
    );
  }

  @override
  Future<DailySubmission> startOrResumeDailyChallenge({DateTime? date}) async {
    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();

    if (_activeSubmission != null &&
        _activeSubmission!.challengeDate.year == utcDate.year &&
        _activeSubmission!.challengeDate.month == utcDate.month &&
        _activeSubmission!.challengeDate.day == utcDate.day) {
      return _activeSubmission!;
    }

    _activeSubmission = DailySubmission(
      challengeDate: utcDate,
      userId: 'local_player',
      status: DailyAttemptStatus.inProgress,
      currentRoundIndex: 1,
      totalScore: 0,
      roundScores: const [],
    );

    return _activeSubmission!;
  }

  @override
  Future<ChallengeResult> submitRoundEvidence({
    required DateTime date,
    required int roundIndex,
    required ChallengeEvidence evidence,
  }) async {
    final challenge = await getDailyChallenge(date: date);
    final chType = challenge.scheduledChallenges[roundIndex - 1];

    // Derive round seed using Mulberry32
    final prng = Mulberry32(challenge.seed);
    var roundSeed = challenge.seed;
    for (var i = 1; i <= roundIndex; i++) {
      roundSeed = prng.nextUint32();
    }

    final def = ChallengeRegistry.getDefinition(chType);
    final config = def.generator.generate(roundSeed);
    final result = def.scorer.score(config, evidence);

    if (_activeSubmission != null) {
      final newScores = List<int>.from(_activeSubmission!.roundScores)..add(result.normalizedScore);
      final isFinished = roundIndex >= 10;

      _activeSubmission = _activeSubmission!.copyWith(
        currentRoundIndex: isFinished ? 10 : roundIndex + 1,
        totalScore: _activeSubmission!.totalScore + result.normalizedScore,
        roundScores: newScores,
        status: isFinished ? DailyAttemptStatus.completed : DailyAttemptStatus.inProgress,
        completedAt: isFinished ? DateTime.now().toUtc() : null,
      );
    }

    return result;
  }

  @override
  Future<List<DailyLeaderboardEntry>> getLeaderboard({
    DateTime? date,
    int limit = 50,
  }) async {
    final userScore = _activeSubmission?.totalScore ?? 0;
    return [
      DailyLeaderboardEntry(
        rank: 1,
        userId: 'top_1',
        username: 'ApexReflex',
        displayName: 'ApexReflex',
        totalScore: math.max(9200, userScore + 500),
      ),
      DailyLeaderboardEntry(
        rank: 2,
        userId: 'top_2',
        username: 'ChronoByte',
        displayName: 'ChronoByte',
        totalScore: math.max(8850, userScore + 200),
      ),
      if (_activeSubmission != null && _activeSubmission!.isCompleted)
        DailyLeaderboardEntry(
          rank: 3,
          userId: 'local_player',
          username: 'YOU',
          displayName: 'YOU',
          totalScore: userScore,
          isCurrentUser: true,
        ),
      DailyLeaderboardEntry(
        rank: 4,
        userId: 'top_4',
        username: 'Synapse9',
        displayName: 'Synapse9',
        totalScore: math.max(7900, userScore - 150),
      ),
    ];
  }

  @override
  Future<DailyUserRankSummary> getUserRank({DateTime? date}) async {
    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
    final tomorrowUtc = DateTime.utc(utcDate.year, utcDate.month, utcDate.day + 1);
    final remaining = tomorrowUtc.difference(DateTime.now().toUtc());

    if (_activeSubmission == null || !_activeSubmission!.isCompleted) {
      return DailyUserRankSummary(
        hasCompleted: false,
        challengeDate: utcDate,
        todayScore: 0,
        globalRank: 0,
        totalParticipants: 0,
        percentile: 100.0,
        nearbyPlayers: const [],
        durationUntilNextChallenge: remaining.isNegative ? Duration.zero : remaining,
      );
    }

    final entries = await getLeaderboard(date: utcDate);

    return DailyUserRankSummary(
      hasCompleted: true,
      challengeDate: utcDate,
      todayScore: _activeSubmission!.totalScore,
      globalRank: 3,
      totalParticipants: 142,
      percentile: 2.1,
      nearbyPlayers: entries,
      durationUntilNextChallenge: remaining.isNegative ? Duration.zero : remaining,
    );
  }
}
