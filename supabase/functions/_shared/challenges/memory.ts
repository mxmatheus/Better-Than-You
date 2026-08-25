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

export interface MemoryConfig extends ChallengeConfig {
  readonly type: 'MEMORY';
  readonly sequenceLength: number;
  readonly sequence: readonly number[];
}

export interface MemoryEvidence extends ChallengeEvidence {
  readonly type: 'MEMORY';
  readonly correctCount: number;
  readonly sequenceLength: number;
  readonly completionTimeMs: number;
  readonly rawTaps: readonly unknown[];
}

export class MemoryGenerator implements ChallengeGenerator<MemoryConfig> {
  public generate(
    seed: number,
    options?: Record<string, unknown>
  ): MemoryConfig {
    const prng = new Mulberry32(seed);
    const length = (options?.sequenceLength as number) ?? 5;

    const sequence: number[] = [];
    let previousTile = -1;

    for (let i = 0; i < length; i++) {
      let tile: number;
      do {
        tile = prng.nextInt(0, 8);
      } while (tile === previousTile);

      sequence.push(tile);
      previousTile = tile;
    }

    return {
      type: 'MEMORY',
      seed,
      sequenceLength: length,
      sequence,
    };
  }
}

export class MemoryValidator
  implements ChallengeValidator<MemoryConfig, MemoryEvidence> {
  public validate(
    config: MemoryConfig,
    evidence: MemoryEvidence
  ): ValidationStatus {
    if (
      evidence.correctCount < 0 ||
      evidence.correctCount > config.sequenceLength ||
      evidence.sequenceLength !== config.sequenceLength
    ) {
      return 'FLAGGED';
    }
    return 'VALID';
  }
}

export class MemoryScorer
  implements ChallengeScorer<MemoryConfig, MemoryEvidence> {
  private readonly validator = new MemoryValidator();

  public score(config: MemoryConfig, evidence: MemoryEvidence): ChallengeResult {
    const status = this.validator.validate(config, evidence);
    const k = evidence.correctCount;
    const length = config.sequenceLength;

    if (status === 'FLAGGED') {
      return {
        type: 'MEMORY',
        normalizedScore: 0,
        rawMetric: k,
        formattedMetric: 'INVALID',
        validationStatus: 'FLAGGED',
      };
    }

    let score = 0;

    if (k === 0) {
      score = 0;
    } else if (k < length) {
      score = Math.round((750 * k) / length);
    } else {
      const speedRatio = Math.max(0, 1 - evidence.completionTimeMs / 6000.0);
      const speedBonus = Math.round(250 * speedRatio);
      score = 750 + speedBonus;
    }

    return {
      type: 'MEMORY',
      normalizedScore: score,
      rawMetric: k,
      formattedMetric: `${k} / ${length}`,
      validationStatus: 'VALID',
    };
  }
}

export class MemoryDefinition
  implements ChallengeDefinition<MemoryConfig, MemoryEvidence> {
  public readonly type = 'MEMORY';
  public readonly family = 'Sequence Memory';
  public readonly maxDurationMs = 12000;
  public readonly generator = new MemoryGenerator();
  public readonly validator = new MemoryValidator();
  public readonly scorer = new MemoryScorer();
}
