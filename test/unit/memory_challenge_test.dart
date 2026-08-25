import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/domain/challenge/challenge_result.dart';
import 'package:better_than_you/domain/challenge/memory/memory_definition.dart';

void main() {
  const definition = MemoryDefinition();
  final generator = definition.generator;
  final validator = definition.validator;
  final scorer = definition.scorer;

  group('Memory Challenge — Deterministic Generation & Sequence Safety', () {
    test('Default sequence length is 5 for ranked', () {
      final config = generator.generate(12345);
      expect(config.sequenceLength, equals(5));
      expect(config.sequence.length, equals(5));
    });

    test('Custom sequence length is respected for daily mode (L=6)', () {
      final config = generator.generate(12345, options: {'sequenceLength': 6});
      expect(config.sequenceLength, equals(6));
      expect(config.sequence.length, equals(6));
    });

    test('Generated sequence never contains consecutive duplicate tiles', () {
      for (var seed = 1; seed <= 200; seed++) {
        final config = generator.generate(
          seed,
          options: {'sequenceLength': 10},
        );
        for (var i = 1; i < config.sequence.length; i++) {
          expect(
            config.sequence[i],
            isNot(equals(config.sequence[i - 1])),
            reason:
                'Seed $seed produced duplicate consecutive tile at index $i (${config.sequence})',
          );
        }
      }
    });

    test('All generated tiles are within 3x3 grid indices [0, 8]', () {
      for (var seed = 100; seed < 150; seed++) {
        final config = generator.generate(seed);
        for (final tile in config.sequence) {
          expect(tile, greaterThanOrEqualTo(0));
          expect(tile, lessThanOrEqualTo(8));
        }
      }
    });

    test('Validation status checks valid and flagged sequences', () {
      final config = generator.generate(100);
      const validEvidence = MemoryEvidence(
        clientTimestampMonoMs: 1000,
        correctCount: 3,
        sequenceLength: 5,
        completionTimeMs: 1000,
        rawTaps: [],
      );
      expect(
        validator.validate(config, validEvidence),
        equals(ValidationStatus.valid),
      );

      const mismatchEvidence = MemoryEvidence(
        clientTimestampMonoMs: 1000,
        correctCount: 3,
        sequenceLength: 6,
        completionTimeMs: 1000,
        rawTaps: [],
      );
      expect(
        validator.validate(config, mismatchEvidence),
        equals(ValidationStatus.flagged),
      );
    });
  });

  group('Memory Challenge — Scoring Accuracy and Speed Bonuses', () {
    final config5 = generator.generate(1337); // L = 5

    test('0/5 correct scores 0 points', () {
      final evidence = MemoryEvidence(
        clientTimestampMonoMs: 1000,
        correctCount: 0,
        sequenceLength: 5,
        completionTimeMs: 1000,
        rawTaps: [],
      );
      final result = scorer.score(config5, evidence);
      expect(result.normalizedScore, equals(0));
      expect(result.formattedMetric, equals('0 / 5'));
    });

    test('1/5 correct scores round(750 * 1 / 5) = 150 points', () {
      final evidence = MemoryEvidence(
        clientTimestampMonoMs: 1000,
        correctCount: 1,
        sequenceLength: 5,
        completionTimeMs: 1000,
        rawTaps: [],
      );
      final result = scorer.score(config5, evidence);
      expect(result.normalizedScore, equals(150));
      expect(result.formattedMetric, equals('1 / 5'));
    });

    test('3/5 correct scores round(750 * 3 / 5) = 450 points', () {
      final evidence = MemoryEvidence(
        clientTimestampMonoMs: 2500,
        correctCount: 3,
        sequenceLength: 5,
        completionTimeMs: 2500,
        rawTaps: [],
      );
      final result = scorer.score(config5, evidence);
      expect(result.normalizedScore, equals(450));
      expect(result.formattedMetric, equals('3 / 5'));
    });

    test('4/5 correct scores round(750 * 4 / 5) = 600 points', () {
      final evidence = MemoryEvidence(
        clientTimestampMonoMs: 3000,
        correctCount: 4,
        sequenceLength: 5,
        completionTimeMs: 3000,
        rawTaps: [],
      );
      final result = scorer.score(config5, evidence);
      expect(result.normalizedScore, equals(600));
      expect(result.formattedMetric, equals('4 / 5'));
    });

    test('5/5 at 6000ms scores exactly base 750 points (0 speed bonus)', () {
      final evidence = MemoryEvidence(
        clientTimestampMonoMs: 6000,
        correctCount: 5,
        sequenceLength: 5,
        completionTimeMs: 6000,
        rawTaps: [],
      );
      final result = scorer.score(config5, evidence);
      expect(result.normalizedScore, equals(750));
      expect(result.formattedMetric, equals('5 / 5'));
    });

    test(
      '5/5 at 0ms scores maximum 1000 points (750 base + 250 speed bonus)',
      () {
        final evidence = MemoryEvidence(
          clientTimestampMonoMs: 0,
          correctCount: 5,
          sequenceLength: 5,
          completionTimeMs: 0,
          rawTaps: [],
        );
        final result = scorer.score(config5, evidence);
        expect(result.normalizedScore, equals(1000));
        expect(result.formattedMetric, equals('5 / 5'));
      },
    );

    test('5/5 at 3000ms scores 750 + round(250 * 0.5) = 875 points', () {
      final evidence = MemoryEvidence(
        clientTimestampMonoMs: 3000,
        correctCount: 5,
        sequenceLength: 5,
        completionTimeMs: 3000,
        rawTaps: [],
      );
      final result = scorer.score(config5, evidence);
      expect(result.normalizedScore, equals(875));
      expect(result.formattedMetric, equals('5 / 5'));
    });
  });
}
