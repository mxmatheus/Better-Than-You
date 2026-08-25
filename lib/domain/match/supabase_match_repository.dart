import 'dart:async';
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
      throw StateError('User must be authenticated to create or find a match');
    }

    // Call authoritative matchmaking RPC
    final response = await _client.rpc('find_or_create_match');
    final status = response['status'] as String? ?? 'QUEUED';

    if (status == 'MATCH_CREATED' || status == 'MATCH_ACTIVE') {
      final matchId = response['match_id'] as String;
      final matchSeed = (response['match_seed'] as num).toInt();
      final roundIndex = response['current_round_index'] as int? ?? 1;

      return MatchSession(
        matchId: matchId,
        matchSeed: matchSeed,
        currentRoundIndex: roundIndex,
        scheduledChallenges: const [
          ChallengeType.reaction,
          ChallengeType.precision,
          ChallengeType.memory,
          ChallengeType.reaction,
          ChallengeType.precision,
          ChallengeType.memory,
          ChallengeType.reaction,
        ],
        state: MatchLifecycleState.roundPreparing,
      );
    }

    // Still in queue
    return MatchSession(
      matchId: 'queue_${user.id}',
      matchSeed: seed ?? 0,
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

    // Fetch authoritative round ID from match_rounds
    final roundRow = await _client
        .from('match_rounds')
        .select('id')
        .eq('match_id', session.matchId)
        .eq('round_index', session.currentRoundIndex)
        .single();

    final roundId = roundRow['id'] as String;

    // Call PostgreSQL RPC: submit_round_evidence
    // Backend authoritatively recalculates score and validation status
    final rpcResult = await _client.rpc('submit_round_evidence', params: {
      'p_round_id': roundId,
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

    // Fetch opponent submission if available or poll for completion
    final opponentSub = await _client
        .from('round_submissions')
        .select('normalized_score, raw_metric, formatted_metric, validation_status')
        .eq('round_id', roundId)
        .neq('player_id', user.id)
        .maybeSingle();

    ChallengeResult opponentResult;
    if (opponentSub != null) {
      opponentResult = ChallengeResult(
        type: session.currentChallengeType,
        normalizedScore: opponentSub['normalized_score'] as int? ?? 0,
        rawMetric: opponentSub['raw_metric'] as num? ?? 0,
        formattedMetric: opponentSub['formatted_metric'] as String? ?? '',
        validationStatus: _parseValidationStatus(
          opponentSub['validation_status'] as String? ?? 'VALID',
        ),
      );
    } else {
      opponentResult = ChallengeResult(
        type: session.currentChallengeType,
        normalizedScore: 0,
        rawMetric: 0,
        formattedMetric: 'WAITING...',
      );
    }

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

  Future<void> cancelMatchmaking() async {
    await _client.rpc('cancel_matchmaking');
  }

  Future<void> forfeitMatch(String matchId) async {
    await _client.rpc('forfeit_match', params: {'p_match_id': matchId});
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
