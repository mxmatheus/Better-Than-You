import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/domain/challenge/challenge_result.dart';
import 'package:better_than_you/domain/challenge/reaction/reaction_definition.dart';

void main() {
  const definition = ReactionDefinition();
  final generator = definition.generator;
  final validator = definition.validator;
  final scorer = definition.scorer;

  group('Reaction Challenge — Deterministic Generation', () {
    test('Wait delay is always within [1500, 4500] ms', () {
      for (var seed = 100; seed < 200; seed++) {
        final config = generator.generate(seed);
        expect(config.waitDelayMs, greaterThanOrEqualTo(1500));
        expect(config.waitDelayMs, lessThanOrEqualTo(4500));
      }
    });

    test('Same seed produces identical wait delay', () {
      final configA = generator.generate(4242);
      final configB = generator.generate(4242);
      expect(configA.waitDelayMs, equals(configB.waitDelayMs));
    });
  });

  group('Reaction Challenge — Validation & Fault Handling', () {
    final config = generator.generate(1337);

    test('Early tap before 100ms triggers earlyFault', () {
      const evidence = ReactionEvidence(
        clientTimestampMonoMs: 1000,
        reactionTimeMs: 85,
        isFault: false,
        triggerRenderedMonoMs: 915,
        touchDownMonoMs: 1000,
      );
      final status = validator.validate(config, evidence);
      expect(status, equals(ValidationStatus.earlyFault));

      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
      expect(result.formattedMetric, equals('FAULT'));
    });

    test('isFault = true triggers earlyFault and 0 score', () {
      const evidence = ReactionEvidence(
        clientTimestampMonoMs: 1000,
        reactionTimeMs: 250,
        isFault: true,
        triggerRenderedMonoMs: 750,
        touchDownMonoMs: 1000,
      );
      final status = validator.validate(config, evidence);
      expect(status, equals(ValidationStatus.earlyFault));

      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
      expect(result.formattedMetric, equals('FAULT'));
    });

    test('Reaction time > 1000ms triggers timeout and 0 score', () {
      const evidence = ReactionEvidence(
        clientTimestampMonoMs: 2500,
        reactionTimeMs: 1050,
        isFault: false,
        triggerRenderedMonoMs: 1450,
        touchDownMonoMs: 2500,
      );
      final status = validator.validate(config, evidence);
      expect(status, equals(ValidationStatus.timeout));

      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
      expect(result.formattedMetric, equals('TIMEOUT'));
    });
  });

  group('Reaction Challenge — Scoring Curve & Boundaries', () {
    final config = generator.generate(1337);

    test('100ms to 160ms yields maximum 1000 score', () {
      for (final t in [100, 120, 140, 160]) {
        final evidence = ReactionEvidence(
          clientTimestampMonoMs: 1000,
          reactionTimeMs: t,
          isFault: false,
          triggerRenderedMonoMs: 1000 - t,
          touchDownMonoMs: 1000,
        );
        final result = scorer.score(config, evidence);
        expect(
          result.normalizedScore,
          equals(1000),
          reason: '$t ms should score 1000',
        );
        expect(result.formattedMetric, equals('$t ms'));
      }
    });

    test('Reaction curve decays monotonically from 160ms to 600ms', () {
      var previousScore = 1000;

      for (var t = 170; t <= 600; t += 10) {
        final evidence = ReactionEvidence(
          clientTimestampMonoMs: 2000,
          reactionTimeMs: t,
          isFault: false,
          triggerRenderedMonoMs: 2000 - t,
          touchDownMonoMs: 2000,
        );
        final result = scorer.score(config, evidence);
        expect(
          result.normalizedScore,
          lessThanOrEqualTo(previousScore),
          reason:
              '$t ms score (${result.normalizedScore}) must be <= previous ($previousScore)',
        );
        expect(result.normalizedScore, greaterThanOrEqualTo(0));
        previousScore = result.normalizedScore;
      }
    });

    test('600ms yields 0 score, >600ms yields 0 score', () {
      final evidence600 = ReactionEvidence(
        clientTimestampMonoMs: 2000,
        reactionTimeMs: 600,
        isFault: false,
        triggerRenderedMonoMs: 1400,
        touchDownMonoMs: 2000,
      );
      expect(scorer.score(config, evidence600).normalizedScore, equals(0));

      final evidence601 = ReactionEvidence(
        clientTimestampMonoMs: 2000,
        reactionTimeMs: 601,
        isFault: false,
        triggerRenderedMonoMs: 1399,
        touchDownMonoMs: 2000,
      );
      expect(scorer.score(config, evidence601).normalizedScore, equals(0));
    });
  });
}
