/**
 * Elo Rating Calculator for BETTER THAN YOU
 * Canonical formulas:
 * EA = 1 / (1 + 10^((RB - RA) / 400))
 * EB = 1 / (1 + 10^((RA - RB) / 400))
 * Verification: EA + EB = 1.0
 */

export interface EloPlayer {
  readonly mmr: number;
  readonly provisionalMatchesRemaining: number;
}

export interface EloOutcomeResult {
  readonly deltaA: number;
  readonly deltaB: number;
  readonly expectedScoreA: number;
  readonly expectedScoreB: number;
}

export class EloCalculator {
  public static getKFactor(player: EloPlayer): number {
    if (player.provisionalMatchesRemaining > 0) {
      return 50; // Provisional acceleration
    }
    if (player.mmr >= 1800) {
      return 20; // High-MMR stabilization
    }
    return 32; // Standard rating
  }

  public static calculateExpectedScore(ra: number, rb: number): number {
    return 1.0 / (1.0 + Math.pow(10.0, (rb - ra) / 400.0));
  }

  public static calculateDeltas(
    playerA: EloPlayer,
    playerB: EloPlayer,
    scoreA: number // 1.0 for A win, 0.5 for draw, 0.0 for A loss
  ): EloOutcomeResult {
    const ea = this.calculateExpectedScore(playerA.mmr, playerB.mmr);
    const eb = 1.0 - ea;

    const scoreB = 1.0 - scoreA;
    const ka = this.getKFactor(playerA);
    const kb = this.getKFactor(playerB);

    let deltaA = Math.round(ka * (scoreA - ea));
    let deltaB = Math.round(kb * (scoreB - eb));

    // Minimum delta guarantee on decisive victories
    if (scoreA === 1.0 && deltaA === 0) {
      deltaA = 1;
      deltaB = -1;
    } else if (scoreA === 0.0 && deltaB === 0) {
      deltaB = 1;
      deltaA = -1;
    }

    return {
      deltaA,
      deltaB,
      expectedScoreA: ea,
      expectedScoreB: eb,
    };
  }
}
