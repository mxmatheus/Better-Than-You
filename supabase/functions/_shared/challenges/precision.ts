import {
  ChallengeConfig,
  ChallengeDefinition,
  ChallengeEvidence,
  ChallengeGenerator,
  ChallengeResult,
  ChallengeScorer,
  ChallengeValidator,
  ValidationStatus,
} from '../challenge_contracts.ts';
import { Mulberry32 } from '../mulberry32.ts';

export interface PrecisionConfig extends ChallengeConfig {
  readonly type: 'PRECISION';
  readonly xTarget: number;
  readonly yTarget: number;
  readonly radiusNorm: number;
  readonly durationMs: number;
}

export interface PrecisionEvidence extends ChallengeEvidence {
  readonly type: 'PRECISION';
  readonly xTouch: number;
  readonly yTouch: number;
  readonly timeToTapMs: number;
  readonly distanceError: number;
}

export class PrecisionGenerator
  implements ChallengeGenerator<PrecisionConfig> {
  public generate(seed: number): PrecisionConfig {
    const prng = new Mulberry32(seed);
    // Safe margin [0.18, 0.82] within [0.0, 1.0] arena
    const xTarget = 0.18 + prng.nextFloat() * 0.64;
    const yTarget = 0.18 + prng.nextFloat() * 0.64;

    return {
      type: 'PRECISION',
      seed,
      xTarget,
      yTarget,
      radiusNorm: 0.12,
      durationMs: 1200,
    };
  }
}

export class PrecisionValidator
  implements ChallengeValidator<PrecisionConfig, PrecisionEvidence> {
  public validate(
    _config: PrecisionConfig,
    evidence: PrecisionEvidence
  ): ValidationStatus {
    if (
      evidence.xTouch < 0.0 ||
      evidence.xTouch > 1.0 ||
      evidence.yTouch < 0.0 ||
      evidence.yTouch > 1.0 ||
      evidence.timeToTapMs < 0
    ) {
      return 'FLAGGED';
    }
    if (evidence.timeToTapMs > 1200) {
      return 'TIMEOUT';
    }
    return 'VALID';
  }
}

export class PrecisionScorer
  implements ChallengeScorer<PrecisionConfig, PrecisionEvidence> {
  private readonly validator = new PrecisionValidator();

  public score(
    config: PrecisionConfig,
    evidence: PrecisionEvidence
  ): ChallengeResult {
    const status = this.validator.validate(config, evidence);

    if (status === 'FLAGGED') {
      return {
        type: 'PRECISION',
        normalizedScore: 0,
        rawMetric: evidence.distanceError,
        formattedMetric: 'FLAGGED',
        validationStatus: 'FLAGGED',
      };
    }

    if (status === 'TIMEOUT') {
      return {
        type: 'PRECISION',
        normalizedScore: 0,
        rawMetric: evidence.distanceError,
        formattedMetric: 'TIMEOUT',
        validationStatus: 'TIMEOUT',
      };
    }

    const dx = evidence.xTouch - config.xTarget;
    const dy = evidence.yTouch - config.yTarget;
    const distance = Math.sqrt(dx * dx + dy * dy);

    if (distance > config.radiusNorm) {
      return {
        type: 'PRECISION',
        normalizedScore: 0,
        rawMetric: distance,
        formattedMetric: 'MISS',
        validationStatus: 'VALID',
      };
    }

    const accuracyRatio = 1.0 - distance / config.radiusNorm;
    const distScore = 850.0 * Math.pow(accuracyRatio, 1.5);
    const speedRatio = Math.max(0, 1.0 - evidence.timeToTapMs / 1200.0);
    const speedScore = 150.0 * speedRatio;
    const finalScore = Math.round(distScore + speedScore);

    return {
      type: 'PRECISION',
      normalizedScore: finalScore,
      rawMetric: distance,
      formattedMetric: `${(accuracyRatio * 100).toFixed(1)}%`,
      validationStatus: 'VALID',
    };
  }
}

export class PrecisionDefinition
  implements ChallengeDefinition<PrecisionConfig, PrecisionEvidence> {
  public readonly type = 'PRECISION';
  public readonly family = 'Target Accuracy';
  public readonly maxDurationMs = 1500;
  public readonly generator = new PrecisionGenerator();
  public readonly validator = new PrecisionValidator();
  public readonly scorer = new PrecisionScorer();
}
