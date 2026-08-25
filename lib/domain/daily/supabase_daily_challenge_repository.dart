import 'package:supabase_flutter/supabase_flutter.dart';
import '../challenge/challenge_evidence.dart';
import '../challenge/challenge_result.dart';
import '../challenge/challenge_type.dart';
import 'daily_challenge.dart';
import 'daily_challenge_repository.dart';
import 'daily_leaderboard_entry.dart';
import 'daily_submission.dart';
import 'daily_user_rank_summary.dart';

final class SupabaseDailyChallengeRepository
    implements DailyChallengeRepository {
  final SupabaseClient _client;

  const SupabaseDailyChallengeRepository({required SupabaseClient client})
    : _client = client;

  @override
  Future<DailyChallenge> getDailyChallenge({DateTime? date}) async {
    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
    final dateStr = _formatDate(utcDate);

    final res = await _client.rpc(
      'get_or_create_daily_challenge',
      params: {'p_date': dateStr},
    );

    final seed = (res['seed'] as num).toInt();
    final schedRaw = (res['scheduled_challenges'] as List<dynamic>)
        .map((e) => ChallengeType.fromString(e.toString()))
        .toList();

    return DailyChallenge(
      challengeDate: utcDate,
      seed: seed,
      scheduledChallenges: schedRaw,
      totalRounds: (res['total_rounds'] as num?)?.toInt() ?? 10,
    );
  }

  @override
  Future<DailySubmission> startOrResumeDailyChallenge({DateTime? date}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'User must be authenticated to start or resume daily challenge',
      );
    }

    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
    final dateStr = _formatDate(utcDate);

    final res = await _client.rpc(
      'start_or_resume_daily_challenge',
      params: {'p_date': dateStr},
    );

    final statusStr = res['status'] as String? ?? 'IN_PROGRESS';
    final roundScoresRaw = res['round_scores'] as List<dynamic>? ?? const [];
    final completedAtStr = res['completed_at'] as String?;

    return DailySubmission(
      challengeDate: utcDate,
      userId: user.id,
      status: DailyAttemptStatus.fromString(statusStr),
      currentRoundIndex: (res['current_round_index'] as num?)?.toInt() ?? 1,
      totalScore: (res['total_score'] as num?)?.toInt() ?? 0,
      roundScores: roundScoresRaw.map((e) => (e as num).toInt()).toList(),
      completedAt: completedAtStr != null
          ? DateTime.parse(completedAtStr)
          : null,
    );
  }

  @override
  Future<ChallengeResult> submitRoundEvidence({
    required DateTime date,
    required int roundIndex,
    required ChallengeEvidence evidence,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to submit round evidence');
    }

    final dateStr = _formatDate(date.toUtc());

    final res = await _client.rpc(
      'submit_daily_round_evidence',
      params: {
        'p_date': dateStr,
        'p_round_index': roundIndex,
        'p_evidence': evidence.toJson(),
        'p_client_version': '1.0.0',
      },
    );

    final authScore = (res['authoritative_score'] as num?)?.toInt() ?? 0;
    final metricText = res['formatted_metric'] as String? ?? '';
    final valStatusStr = res['validation_status'] as String? ?? 'VALID';
    final chTypeStr = res['challenge_type'] as String? ?? 'REACTION';

    return ChallengeResult(
      type: ChallengeType.fromString(chTypeStr),
      normalizedScore: authScore,
      rawMetric: authScore,
      formattedMetric: metricText,
      validationStatus: _parseValidationStatus(valStatusStr),
    );
  }

  @override
  Future<List<DailyLeaderboardEntry>> getLeaderboard({
    DateTime? date,
    int limit = 50,
  }) async {
    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
    final dateStr = _formatDate(utcDate);
    final user = _client.auth.currentUser;

    final res = await _client.rpc(
      'get_daily_leaderboard',
      params: {'p_date': dateStr, 'p_limit': limit},
    );

    final list = res as List<dynamic>? ?? const [];
    return list
        .map(
          (e) => DailyLeaderboardEntry.fromJson(
            e as Map<String, dynamic>,
            currentUserId: user?.id,
          ),
        )
        .toList();
  }

  @override
  Future<DailyUserRankSummary> getUserRank({DateTime? date}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
      return DailyUserRankSummary(
        hasCompleted: false,
        challengeDate: utcDate,
        todayScore: 0,
        globalRank: 0,
        totalParticipants: 0,
        percentile: 100.0,
        nearbyPlayers: const [],
        durationUntilNextChallenge: Duration.zero,
      );
    }

    final utcDate = date?.toUtc() ?? DateTime.now().toUtc();
    final dateStr = _formatDate(utcDate);

    final res = await _client.rpc(
      'get_daily_user_rank',
      params: {'p_date': dateStr},
    );

    return DailyUserRankSummary.fromJson(
      res as Map<String, dynamic>,
      currentUserId: user.id,
    );
  }

  String _formatDate(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  ValidationStatus _parseValidationStatus(String status) {
    switch (status.toUpperCase()) {
      case 'EARLY_FAULT':
        return ValidationStatus.earlyFault;
      case 'TIMEOUT':
        return ValidationStatus.timeout;
      case 'FLAGGED':
        return ValidationStatus.flagged;
      case 'REJECTED':
      case 'REJECTED_LATE':
        return ValidationStatus.rejectedLate;
      default:
        return ValidationStatus.valid;
    }
  }
}
