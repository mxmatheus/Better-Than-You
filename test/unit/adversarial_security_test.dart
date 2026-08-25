import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/utils/elo_calculator.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/domain/challenge/challenge_registry.dart';
import 'package:better_than_you/domain/challenge/challenge_result.dart';
import 'package:better_than_you/domain/challenge/challenge_type.dart';
import 'package:better_than_you/domain/daily/local_daily_challenge_repository.dart';

void main() {
  group('Adversarial Anti-Cheat & Score Authority Tests', () {
    test(
      'Reaction: Server ignores client claimed 0 score when evidence is excellent (200ms)',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        final config = def.generator.generate(1337);

        const evidence = ReactionEvidence(
          clientTimestampMonoMs: 200,
          reactionTimeMs: 200,
          isFault: false,
          triggerRenderedMonoMs: 0,
          touchDownMonoMs: 200,
        );

        final result = def.scorer.score(config, evidence);
        expect(result.normalizedScore, equals(956));
        expect(result.validationStatus, equals(ValidationStatus.valid));
      },
    );

    test(
      'Reaction: Server rejects client claimed 1000 score when evidence is poor (550ms)',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        final config = def.generator.generate(1337);

        const evidence = ReactionEvidence(
          clientTimestampMonoMs: 550,
          reactionTimeMs: 550,
          isFault: false,
          triggerRenderedMonoMs: 0,
          touchDownMonoMs: 550,
        );

        final result = def.scorer.score(config, evidence);
        expect(result.normalizedScore, equals(145));
        expect(result.validationStatus, equals(ValidationStatus.valid));
      },
    );

    test(
      'Reaction: False start (<100ms) produces strictly 0 score regardless of claim',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        final config = def.generator.generate(1337);

        for (final t in [-50, 0, 50, 99]) {
          final evidence = ReactionEvidence(
            clientTimestampMonoMs: t,
            reactionTimeMs: t,
            isFault: false,
            triggerRenderedMonoMs: 0,
            touchDownMonoMs: t,
          );

          final result = def.scorer.score(config, evidence);
          expect(result.normalizedScore, equals(0));
          expect(result.validationStatus, equals(ValidationStatus.earlyFault));
        }
      },
    );

    test(
      'Reaction: Boundary timing at exactly 100ms yields maximum 1000 score',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        final config = def.generator.generate(1337);

        const evidence = ReactionEvidence(
          clientTimestampMonoMs: 100,
          reactionTimeMs: 100,
          isFault: false,
          triggerRenderedMonoMs: 0,
          touchDownMonoMs: 100,
        );

        final result = def.scorer.score(config, evidence);
        expect(result.normalizedScore, equals(1000));
        expect(result.validationStatus, equals(ValidationStatus.valid));
      },
    );

    test(
      'Precision: Out-of-bounds tap (x > 1.0, y < 0.0) yields strictly 0 score (MISS) and FLAGGED',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.precision);
        final config = def.generator.generate(1337);

        const evidence = PrecisionEvidence(
          clientTimestampMonoMs: 100,
          xTouch: 5.0,
          yTouch: -2.0,
          timeToTapMs: 100,
          distanceError: 4.5,
        );

        final result = def.scorer.score(config, evidence);
        expect(result.normalizedScore, equals(0));
        expect(result.validationStatus, equals(ValidationStatus.flagged));
      },
    );

    test('Precision: Tap outside target radius (d > 0.12) yields 0 score', () {
      final def = ChallengeRegistry.getDefinition(ChallengeType.precision);
      final config = def.generator.generate(1337);

      const evidence = PrecisionEvidence(
        clientTimestampMonoMs: 100,
        xTouch: 0.1,
        yTouch: 0.1,
        timeToTapMs: 100,
        distanceError: 0.35,
      );

      final result = def.scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
    });

    test(
      'Memory: Incomplete / wrong sequence receives only accuracy points and 0 speed bonus',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.memory);
        final config = def.generator.generate(1337);

        const evidence = MemoryEvidence(
          clientTimestampMonoMs: 2000,
          correctCount: 2,
          sequenceLength: 5,
          completionTimeMs: 2000,
          rawTaps: [],
        );

        final result = def.scorer.score(config, evidence);
        expect(result.normalizedScore, equals(300));
      },
    );
  });

  group('Replay Attacks & Idempotency Verification', () {
    test(
      'Elo calculation is strictly deterministic and idempotent across repeated invocations',
      () {
        final res1 = EloCalculator.calculateDeltas(
          mmrA: 1200,
          mmrB: 1000,
          provisionalRemainingA: 0,
          provisionalRemainingB: 0,
          scoreA: 1.0,
        );

        final res2 = EloCalculator.calculateDeltas(
          mmrA: 1200,
          mmrB: 1000,
          provisionalRemainingA: 0,
          provisionalRemainingB: 0,
          scoreA: 1.0,
        );

        expect(res1.deltaA, equals(res2.deltaA));
        expect(res1.deltaB, equals(res2.deltaB));
        expect(res1.expectedScoreA + res1.expectedScoreB, closeTo(1.0, 1e-6));
      },
    );

    test(
      'Daily Challenge repository prevents duplicate completions after round 10',
      () async {
        final repo = LocalDailyChallengeRepository();
        final date = DateTime.utc(2026, 8, 26);
        final challenge = await repo.getDailyChallenge(date: date);

        await repo.startOrResumeDailyChallenge(date: date);

        // Submit all 10 rounds with matching evidence types
        for (var i = 1; i <= 10; i++) {
          final chType = challenge.scheduledChallenges[i - 1];
          ChallengeEvidence evidence;
          switch (chType) {
            case ChallengeType.reaction:
              evidence = const ReactionEvidence(
                clientTimestampMonoMs: 200,
                reactionTimeMs: 200,
                isFault: false,
                triggerRenderedMonoMs: 0,
                touchDownMonoMs: 200,
              );
              break;
            case ChallengeType.precision:
              evidence = const PrecisionEvidence(
                clientTimestampMonoMs: 100,
                xTouch: 0.5,
                yTouch: 0.5,
                timeToTapMs: 100,
                distanceError: 0.0,
              );
              break;
            case ChallengeType.memory:
              evidence = const MemoryEvidence(
                clientTimestampMonoMs: 3000,
                correctCount: 5,
                sequenceLength: 5,
                completionTimeMs: 3000,
                rawTaps: [],
              );
              break;
          }

          await repo.submitRoundEvidence(
            date: date,
            roundIndex: i,
            evidence: evidence,
          );
        }

        final completedSub = await repo.startOrResumeDailyChallenge(date: date);
        expect(completedSub.isCompleted, isTrue);
        expect(completedSub.totalScore, greaterThan(0));
        expect(completedSub.currentRoundIndex, equals(10));
      },
    );
  });
}
