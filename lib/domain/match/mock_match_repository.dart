import 'dart:math' as math;
import '../../core/utils/mulberry32.dart';
import '../challenge/challenge_config.dart';
import '../challenge/challenge_evidence.dart';
import '../challenge/challenge_registry.dart';
import '../challenge/challenge_result.dart';
import '../challenge/challenge_type.dart';
import 'match_repository.dart';
import 'match_session.dart';
import 'match_state.dart';
import 'round_result.dart';

final class MockMatchRepository implements MatchRepository {
  const MockMatchRepository();

  @override
  Future<MatchSession> createMatch({int? seed}) async {
    final matchSeed = seed ?? (DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF);
    return MatchSession(
      matchId: 'local_demo_${matchSeed.toRadixString(16)}',
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
      state: MatchLifecycleState.roundPreparing,
    );
  }

  @override
  Future<RoundResult> submitRoundEvidence({
    required MatchSession session,
    required ChallengeEvidence evidence,
  }) async {
    final type = session.currentChallengeType;
    final def = ChallengeRegistry.getDefinition(type);
    final config = def.generator.generate(session.currentRoundSeed);

    // Score player evidence authoritatively
    final playerResult = def.scorer.score(config, evidence);

    // Generate deterministic opponent evidence
    final opponentResult = _generateMockOpponentResult(
      type: type,
      config: config,
      seed: (session.currentRoundSeed + 0xDEADBEEF) & 0xFFFFFFFF,
    );

    final outcome = RoundResult.determineOutcome(playerResult, opponentResult);

    return RoundResult(
      roundIndex: session.currentRoundIndex,
      challengeType: type,
      playerResult: playerResult,
      opponentResult: opponentResult,
      outcome: outcome,
    );
  }

  @override
  Future<MatchSession> nextRound(MatchSession session) async {
    final nextRoundIndex = session.currentRoundIndex + 1;
    final isFinished = session.isMatchOver || nextRoundIndex > session.totalRounds;

    return session.copyWith(
      currentRoundIndex: nextRoundIndex,
      state: isFinished
          ? MatchLifecycleState.matchCompleted
          : MatchLifecycleState.roundPreparing,
    );
  }

  ChallengeResult _generateMockOpponentResult({
    required ChallengeType type,
    required ChallengeConfig config,
    required int seed,
  }) {
    final prng = Mulberry32(seed);

    switch (type) {
      case ChallengeType.reaction:
        final oppReactionMs = prng.nextInt(200, 360);
        final def = ChallengeRegistry.getDefinition(type);
        return def.scorer.score(
          config,
          ReactionEvidence(
            clientTimestampMonoMs: oppReactionMs,
            reactionTimeMs: oppReactionMs,
            isFault: false,
            triggerRenderedMonoMs: 0,
            touchDownMonoMs: oppReactionMs,
          ),
        );

      case ChallengeType.memory:
        final memConfig = config as MemoryConfig;
        // Opponent gets 4 or 5 correct
        final correctCount = prng.nextInt(memConfig.sequenceLength - 1, memConfig.sequenceLength);
        final completionTime = prng.nextInt(2500, 4800);
        final def = ChallengeRegistry.getDefinition(type);
        return def.scorer.score(
          config,
          MemoryEvidence(
            clientTimestampMonoMs: completionTime,
            correctCount: correctCount,
            sequenceLength: memConfig.sequenceLength,
            completionTimeMs: completionTime,
            rawTaps: const [],
          ),
        );

      case ChallengeType.precision:
        final precConfig = config as PrecisionConfig;
        // Opponent hits within target radius with small offset
        final angle = prng.nextFloat() * 2 * math.pi;
        final dist = prng.nextFloat() * (precConfig.radiusNorm * 0.7);
        final x = precConfig.xTarget + dist * math.cos(angle);
        final y = precConfig.yTarget + dist * math.sin(angle);
        final tapTime = prng.nextInt(400, 850);
        final def = ChallengeRegistry.getDefinition(type);
        return def.scorer.score(
          config,
          PrecisionEvidence(
            clientTimestampMonoMs: tapTime,
            xTouch: x,
            yTouch: y,
            timeToTapMs: tapTime,
            distanceError: dist,
          ),
        );
    }
  }
}
