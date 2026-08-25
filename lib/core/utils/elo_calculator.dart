import 'dart:math' as math;

final class EloOutcomeResult {
  final int deltaA;
  final int deltaB;
  final double expectedScoreA;
  final double expectedScoreB;

  const EloOutcomeResult({
    required this.deltaA,
    required this.deltaB,
    required this.expectedScoreA,
    required this.expectedScoreB,
  });
}

abstract final class EloCalculator {
  static int getKFactor({required int mmr, required int provisionalRemaining}) {
    if (provisionalRemaining > 0) {
      return 50; // Provisional acceleration
    }
    if (mmr >= 1800) {
      return 20; // High-MMR stabilization
    }
    return 32; // Standard rating
  }

  static double calculateExpectedScore(int ra, int rb) {
    return 1.0 / (1.0 + math.pow(10.0, (rb - ra) / 400.0));
  }

  static EloOutcomeResult calculateDeltas({
    required int mmrA,
    required int mmrB,
    required int provisionalRemainingA,
    required int provisionalRemainingB,
    required double scoreA, // 1.0 for A win, 0.5 for draw, 0.0 for A loss
  }) {
    final ea = calculateExpectedScore(mmrA, mmrB);
    final eb = 1.0 - ea;

    final scoreB = 1.0 - scoreA;
    final ka = getKFactor(
      mmr: mmrA,
      provisionalRemaining: provisionalRemainingA,
    );
    final kb = getKFactor(
      mmr: mmrB,
      provisionalRemaining: provisionalRemainingB,
    );

    var deltaA = (ka * (scoreA - ea)).round();
    var deltaB = (kb * (scoreB - eb)).round();

    // Minimum delta guarantee on decisive victories
    if (scoreA == 1.0 && deltaA == 0) {
      deltaA = 1;
      deltaB = -1;
    } else if (scoreA == 0.0 && deltaB == 0) {
      deltaB = 1;
      deltaA = -1;
    }

    return EloOutcomeResult(
      deltaA: deltaA,
      deltaB: deltaB,
      expectedScoreA: ea,
      expectedScoreB: eb,
    );
  }
}
