import '../challenge/challenge_evidence.dart';
import '../challenge/challenge_result.dart';
import 'daily_challenge.dart';
import 'daily_leaderboard_entry.dart';
import 'daily_submission.dart';
import 'daily_user_rank_summary.dart';

abstract interface class DailyChallengeRepository {
  Future<DailyChallenge> getDailyChallenge({DateTime? date});

  Future<DailySubmission> startOrResumeDailyChallenge({DateTime? date});

  Future<ChallengeResult> submitRoundEvidence({
    required DateTime date,
    required int roundIndex,
    required ChallengeEvidence evidence,
  });

  Future<List<DailyLeaderboardEntry>> getLeaderboard({
    DateTime? date,
    int limit = 50,
  });

  Future<DailyUserRankSummary> getUserRank({DateTime? date});
}
