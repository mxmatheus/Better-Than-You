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

export interface ReactionConfig extends ChallengeConfig {
  readonly type: 'REACTION';
  readonly waitDelayMs: number;
}

export interface ReactionEvidence extends ChallengeEvidence {
  readonly type: 'REACTION';
  readonly reactionTimeMs: number;
  readonly isFault: boolean;
  readonly triggerRenderedMonoMs: number;
  readonly touchDownMonoMs: number;
}

export class ReactionGenerator implements ChallengeGenerator<ReactionConfig> {
  public generate(seed: number): ReactionConfig {
    const prng = new Mulberry32(seed);
    const waitDelayMs = prng.nextInt(1500, 4500);
    return {
      type: 'REACTION',
      seed,
      waitDelayMs,
    };
  }
}

export class ReactionValidator
  implements ChallengeValidator<ReactionConfig, ReactionEvidence> {
  public validate(
    _config: ReactionConfig,
    evidence: ReactionEvidence
  ): ValidationStatus {
    if (evidence.isFault || evidence.reactionTimeMs < 100) {
      return 'EARLY_FAULT';
    }
    if (evidence.reactionTimeMs > 1000) {
      return 'TIMEOUT';
    }
    return 'VALID';
  }
}

export class ReactionScorer
  implements ChallengeScorer<ReactionConfig, ReactionEvidence> {
  private readonly validator = new ReactionValidator();

  public score(
    config: ReactionConfig,
    evidence: ReactionEvidence
  ): ChallengeResult {
    const status = this.validator.validate(config, evidence);

    if (status === 'EARLY_FAULT') {
      return {
        type: 'REACTION',
        normalizedScore: 0,
        rawMetric: evidence.reactionTimeMs,
        formattedMetric: 'FAULT',
        validationStatus: 'EARLY_FAULT',
      };
    }

    if (status === 'TIMEOUT') {
      return {
        type: 'REACTION',
        normalizedScore: 0,
        rawMetric: evidence.reactionTimeMs,
        formattedMetric: 'TIMEOUT',
        validationStatus: 'TIMEOUT',
      };
    }

    const t = evidence.reactionTimeMs;
    let score = 0;

    if (t >= 100 && t <= 160) {
      score = 1000;
    } else if (t > 160 && t <= 600) {
      const decay = Math.pow((t - 160) / 440.0, 1.3);
      score = Math.max(0, Math.round(1000 * (1 - decay)));
    } else {
      score = 0;
    }

    return {
      type: 'REACTION',
      normalizedScore: score,
      rawMetric: t,
      formattedMetric: `${t} ms`,
      validationStatus: 'VALID',
    };
  }
}

export class ReactionDefinition
  implements ChallengeDefinition<ReactionConfig, ReactionEvidence> {
  public readonly type = 'REACTION';
  public readonly family = 'Visual Reflex';
  public readonly maxDurationMs = 5500;
  public readonly generator = new ReactionGenerator();
  public readonly validator = new ReactionValidator();
  public readonly scorer = new ReactionScorer();
}
