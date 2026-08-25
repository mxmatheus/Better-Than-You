import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/utils/elo_calculator.dart';

void main() {
  group('Elo Calculator — Canonical Mathematical Model & Invariants', () {
    test('Expected scores sum to exactly 1.0 (EA + EB = 1.0)', () {
      for (var ra = 800; ra <= 2400; ra += 100) {
        for (var rb = 800; rb <= 2400; rb += 100) {
          final ea = EloCalculator.calculateExpectedScore(ra, rb);
          final eb = EloCalculator.calculateExpectedScore(rb, ra);
          expect(ea + eb, closeTo(1.0, 1e-9),
              reason: 'EA + EB must equal 1.0 for RA=$ra, RB=$rb');
        }
      }
    });

    test('Worked Example 1: Equal rating (RA=1000, RB=1000, K=32)', () {
      final res = EloCalculator.calculateDeltas(
        mmrA: 1000,
        mmrB: 1000,
        provisionalRemainingA: 0,
        provisionalRemainingB: 0,
        scoreA: 1.0, // A wins
      );

      expect(res.expectedScoreA, closeTo(0.5, 1e-6));
      expect(res.expectedScoreB, closeTo(0.5, 1e-6));
      expect(res.deltaA, equals(16));
      expect(res.deltaB, equals(-16));
    });

    test('Worked Example 2: RA=1200, RB=1000, Standard K=32', () {
      // A Wins
      final winRes = EloCalculator.calculateDeltas(
        mmrA: 1200,
        mmrB: 1000,
        provisionalRemainingA: 0,
        provisionalRemainingB: 0,
        scoreA: 1.0,
      );

      expect(winRes.expectedScoreA, closeTo(0.7597, 1e-3));
      expect(winRes.expectedScoreB, closeTo(0.2403, 1e-3));
      expect(winRes.deltaA, equals(8));
      expect(winRes.deltaB, equals(-8));

      // B Wins (A Loses)
      final lossRes = EloCalculator.calculateDeltas(
        mmrA: 1200,
        mmrB: 1000,
        provisionalRemainingA: 0,
        provisionalRemainingB: 0,
        scoreA: 0.0,
      );

      expect(lossRes.deltaA, equals(-24));
      expect(lossRes.deltaB, equals(24));
    });

    test('Worked Example 3: RA=1800 (K=20), RB=1000 (K=32), Minimum Delta Guarantee', () {
      final res = EloCalculator.calculateDeltas(
        mmrA: 1800,
        mmrB: 1000,
        provisionalRemainingA: 0,
        provisionalRemainingB: 0,
        scoreA: 1.0, // High MMR player wins
      );

      expect(res.expectedScoreA, closeTo(0.9901, 1e-3));
      expect(res.expectedScoreB, closeTo(0.0099, 1e-3));
      // Without minimum delta, deltaA would round to 0. Guaranteed minimum is +1 / -1
      expect(res.deltaA, greaterThanOrEqualTo(1));
      expect(res.deltaB, lessThanOrEqualTo(-1));
    });

    test('Provisional K-Factor is 50 when provisional matches remain', () {
      final res = EloCalculator.calculateDeltas(
        mmrA: 1000,
        mmrB: 1000,
        provisionalRemainingA: 10,
        provisionalRemainingB: 10,
        scoreA: 1.0,
      );

      expect(res.deltaA, equals(25)); // 50 * 0.5 = 25
      expect(res.deltaB, equals(-25));
    });
  });
}
