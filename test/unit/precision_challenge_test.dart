import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/domain/challenge/challenge_result.dart';
import 'package:better_than_you/domain/challenge/precision/precision_definition.dart';

void main() {
  const definition = PrecisionDefinition();
  final generator = definition.generator;
  final validator = definition.validator;
  final scorer = definition.scorer;

  group('Precision Challenge — Deterministic Generation & Boundaries', () {
    test('Target coordinates are always within safe margin [0.18, 0.82]^2', () {
      for (var seed = 1; seed <= 200; seed++) {
        final config = generator.generate(seed);
        expect(config.xTarget, greaterThanOrEqualTo(0.18));
        expect(config.xTarget, lessThanOrEqualTo(0.82));
        expect(config.yTarget, greaterThanOrEqualTo(0.18));
        expect(config.yTarget, lessThanOrEqualTo(0.82));
        expect(config.radiusNorm, equals(0.12));
      }
    });

    test('Same seed produces identical target coordinate', () {
      final configA = generator.generate(999);
      final configB = generator.generate(999);
      expect(configA.xTarget, equals(configB.xTarget));
      expect(configA.yTarget, equals(configB.yTarget));
    });

    test('Validator checks coordinate bounds', () {
      final config = generator.generate(100);
      const validEvidence = PrecisionEvidence(
        clientTimestampMonoMs: 200,
        xTouch: 0.5,
        yTouch: 0.5,
        timeToTapMs: 200,
        distanceError: 0.05,
      );
      expect(
        validator.validate(config, validEvidence),
        equals(ValidationStatus.valid),
      );

      const outOfBoundsEvidence = PrecisionEvidence(
        clientTimestampMonoMs: 200,
        xTouch: 1.5,
        yTouch: 0.5,
        timeToTapMs: 200,
        distanceError: 0.05,
      );
      expect(
        validator.validate(config, outOfBoundsEvidence),
        equals(ValidationStatus.flagged),
      );
    });
  });

  group('Precision Challenge — Scoring Accuracy & Timing Dynamics', () {
    final config = generator.generate(1337);

    test('Dead center hit at 0ms scores maximum 1000 points', () {
      final evidence = PrecisionEvidence(
        clientTimestampMonoMs: 0,
        xTouch: config.xTarget,
        yTouch: config.yTarget,
        timeToTapMs: 0,
        distanceError: 0.0,
      );
      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(1000));
      expect(result.formattedMetric, equals('100.0%'));
    });

    test(
      'Exact boundary hit (d = 0.12) at 0ms scores speed bonus only (150 pts)',
      () {
        final evidence = PrecisionEvidence(
          clientTimestampMonoMs: 0,
          xTouch: config.xTarget + 0.12,
          yTouch: config.yTarget,
          timeToTapMs: 0,
          distanceError: 0.12,
        );
        final result = scorer.score(config, evidence);
        expect(result.normalizedScore, equals(150));
        expect(result.formattedMetric, equals('0.0%'));
      },
    );

    test('Outside target boundary (d > 0.12) scores 0 points (MISS)', () {
      final evidence = PrecisionEvidence(
        clientTimestampMonoMs: 200,
        xTouch: config.xTarget + 0.121,
        yTouch: config.yTarget,
        timeToTapMs: 200,
        distanceError: 0.121,
      );
      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
      expect(result.formattedMetric, equals('MISS'));
    });

    test('Timeout (t > 1200ms) scores 0 points (TIMEOUT)', () {
      final evidence = PrecisionEvidence(
        clientTimestampMonoMs: 1250,
        xTouch: config.xTarget,
        yTouch: config.yTarget,
        timeToTapMs: 1250,
        distanceError: 0.0,
      );
      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
      expect(result.formattedMetric, equals('TIMEOUT'));
    });

    test('Negative tap time (t < 0) scores 0 points', () {
      final evidence = PrecisionEvidence(
        clientTimestampMonoMs: 0,
        xTouch: config.xTarget,
        yTouch: config.yTarget,
        timeToTapMs: -10,
        distanceError: 0.0,
      );
      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(0));
    });

    test('Mid-distance hit scales accuracy exponentially', () {
      final evidence = PrecisionEvidence(
        clientTimestampMonoMs: 600,
        xTouch: config.xTarget + 0.06,
        yTouch: config.yTarget,
        timeToTapMs: 600,
        distanceError: 0.06,
      );
      final result = scorer.score(config, evidence);
      expect(result.normalizedScore, equals(376));
      expect(result.formattedMetric, equals('50.0%'));
    });
  });
}
