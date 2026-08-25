import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_config.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/domain/challenge/challenge_registry.dart';
import 'package:better_than_you/domain/challenge/challenge_result.dart';
import 'package:better_than_you/domain/challenge/challenge_type.dart';
import 'package:better_than_you/domain/match/match_session.dart';
import 'package:better_than_you/domain/match/match_state.dart';

void main() {
  group('Backend Authority & Client Untrusted Score Verification', () {
    test(
      'Reaction: Authoritative scorer recalculates from raw timestamps, overriding client claim',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        const config = ReactionConfig(seed: 1337, waitDelayMs: 2500);

        // Malicious or mismatched client claiming score = 999
        const evidence = ReactionEvidence(
          clientTimestampMonoMs: 250,
          reactionTimeMs: 250,
          isFault: false,
          triggerRenderedMonoMs: 0,
          touchDownMonoMs: 250,
        );

        final authoritativeResult = def.scorer.score(config, evidence);

        // Score for 250ms reaction time is 873, NOT 999
        expect(authoritativeResult.normalizedScore, equals(873));
        expect(
          authoritativeResult.validationStatus,
          equals(ValidationStatus.valid),
        );
        expect(authoritativeResult.formattedMetric, equals('250 ms'));
      },
    );

    test(
      'Reaction: False start (<100ms) is rejected by server authority regardless of client claim',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        const config = ReactionConfig(seed: 1337, waitDelayMs: 2500);

        const falseStartEvidence = ReactionEvidence(
          clientTimestampMonoMs: 50,
          reactionTimeMs: 50,
          isFault: false,
          triggerRenderedMonoMs: 0,
          touchDownMonoMs: 50,
        );

        final authoritativeResult = def.scorer.score(
          config,
          falseStartEvidence,
        );

        expect(authoritativeResult.normalizedScore, equals(0));
        expect(
          authoritativeResult.validationStatus,
          equals(ValidationStatus.earlyFault),
        );
        expect(authoritativeResult.formattedMetric, equals('FAULT'));
      },
    );

    test(
      'Precision: Out of bounds tap (d > 0.12) is scored as 0 (MISS) by server authority',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.precision);
        const config = PrecisionConfig(
          seed: 1337,
          xTarget: 0.5,
          yTarget: 0.5,
          radiusNorm: 0.12,
          durationMs: 1200,
        );

        // Tap at (0.8, 0.5) => distance 0.30 > 0.12
        const outOfBoundsEvidence = PrecisionEvidence(
          clientTimestampMonoMs: 200,
          xTouch: 0.8,
          yTouch: 0.5,
          timeToTapMs: 200,
          distanceError: 0.30,
        );

        final authoritativeResult = def.scorer.score(
          config,
          outOfBoundsEvidence,
        );

        expect(authoritativeResult.normalizedScore, equals(0));
        expect(authoritativeResult.formattedMetric, equals('MISS'));
      },
    );

    test(
      'MatchSession terminates early as soon as target wins (4) are reached',
      () {
        const scheduled = [
          ChallengeType.reaction,
          ChallengeType.precision,
          ChallengeType.memory,
          ChallengeType.reaction,
          ChallengeType.precision,
          ChallengeType.memory,
          ChallengeType.reaction,
        ];

        var session = const MatchSession(
          matchId: 'test_match_001',
          matchSeed: 9999,
          targetWins: 4,
          totalRounds: 7,
          scheduledChallenges: scheduled,
        );

        expect(session.isMatchOver, isFalse);

        // Win 3 rounds
        session = session.copyWith(playerWins: 3, currentRoundIndex: 4);
        expect(session.isMatchOver, isFalse);

        // Win 4th round (reaches targetWins)
        session = session.copyWith(playerWins: 4, currentRoundIndex: 5);
        expect(session.isMatchOver, isTrue);
        expect(session.overallWinner, equals(RoundOutcome.win));
      },
    );
  });
}
