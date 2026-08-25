import 'package:supabase_flutter/supabase_flutter.dart';
import '../challenge/challenge_evidence.dart';
import '../challenge/challenge_result.dart';
import '../challenge/challenge_type.dart';
import 'match_repository.dart';
import 'match_session.dart';
import 'match_state.dart';
import 'round_result.dart';

final class SupabaseMatchRepository implements MatchRepository {
  final SupabaseClient _client;

  const SupabaseMatchRepository({
    required SupabaseClient client,
  }) : _client = client;

  @override
  Future<MatchSession> createMatch({int? seed}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to create a Supabase match');
    }

    final matchSeed =
        seed ?? (DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF);

    final response = await _client.from('matches').insert({
      'player_a_id': user.id,
      'match_seed': matchSeed,
      'scheduled_challenges': [
        'REACTION',
        'PRECISION',
        'MEMORY',
        'REACTION',
        'PRECISION',
        'MEMORY',
        'REACTION',
      ],
      'player_a_mmr_start': 1000,
      'status': 'MATCHMAKING',
    }).select().single();

    return MatchSession(
      matchId: response['id'] as String,
      matchSeed: matchSeed,
      scheduledChallenges: const [
        ChallengeType.reaction,
        ChallengeType.precision,
        ChallengeType.memory,
        ChallengeType.reaction,
        ChallengeType.precision,
        ChallengeType.memory,
        ChallengeType.reaction,
      ],
      state: MatchLifecycleState.matchmaking,
    );
  }

  @override
  Future<RoundResult> submitRoundEvidence({
    required MatchSession session,
    required ChallengeEvidence evidence,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to submit evidence');
    }

    // Call PostgreSQL RPC: submit_round_evidence
    // Backend authoritatively recalculates score and validation status
    final rpcResult = await _client.rpc('submit_round_evidence', params: {
      'p_round_id': session.matchId,
      'p_evidence': evidence.toJson(),
      'p_client_claimed_score': null,
      'p_client_version': '1.0.0',
    });

    final authScore = rpcResult['authoritative_score'] as int? ?? 0;
    final metricText = rpcResult['formatted_metric'] as String? ?? '';
    final valStatusStr = rpcResult['validation_status'] as String? ?? 'VALID';

    final playerResult = ChallengeResult(
      type: session.currentChallengeType,
      normalizedScore: authScore,
      rawMetric: authScore,
      formattedMetric: metricText,
      validationStatus: _parseValidationStatus(valStatusStr),
    );

    // Placeholder opponent result until Realtime broadcast resolves round
    final opponentResult = ChallengeResult(
      type: session.currentChallengeType,
      normalizedScore: 0,
      rawMetric: 0,
      formattedMetric: 'PENDING',
    );

    return RoundResult(
      roundIndex: session.currentRoundIndex,
      challengeType: session.currentChallengeType,
      playerResult: playerResult,
      opponentResult: opponentResult,
      outcome: RoundResult.determineOutcome(playerResult, opponentResult),
    );
  }

  @override
  Future<MatchSession> nextRound(MatchSession session) async {
    final nextRoundIndex = session.currentRoundIndex + 1;
    final isFinished =
        session.isMatchOver || nextRoundIndex > session.totalRounds;

    return session.copyWith(
      currentRoundIndex: nextRoundIndex,
      state: isFinished
          ? MatchLifecycleState.matchCompleted
          : MatchLifecycleState.roundPreparing,
    );
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
