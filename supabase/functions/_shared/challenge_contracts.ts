export type ChallengeType = 'REACTION' | 'MEMORY' | 'PRECISION';

export type ValidationStatus =
  | 'VALID'
  | 'FLAGGED'
  | 'EARLY_FAULT'
  | 'TIMEOUT'
  | 'REJECTED';

export interface ChallengeConfig {
  readonly type: ChallengeType;
  readonly seed: number;
}

export interface ChallengeEvidence {
  readonly type: ChallengeType;
  readonly clientTimestampMonoMs: number;
  readonly [key: string]: unknown;
}

export interface ChallengeResult {
  readonly type: ChallengeType;
  readonly normalizedScore: number;
  readonly rawMetric: number;
  readonly formattedMetric: string;
  readonly validationStatus: ValidationStatus;
}

export interface ChallengeGenerator<TConfig extends ChallengeConfig> {
  generate(seed: number, options?: Record<string, unknown>): TConfig;
}

export interface ChallengeValidator<
  TConfig extends ChallengeConfig,
  TEvidence extends ChallengeEvidence
> {
  validate(config: TConfig, evidence: TEvidence): ValidationStatus;
}

export interface ChallengeScorer<
  TConfig extends ChallengeConfig,
  TEvidence extends ChallengeEvidence
> {
  score(config: TConfig, evidence: TEvidence): ChallengeResult;
}

export interface ChallengeDefinition<
  TConfig extends ChallengeConfig,
  TEvidence extends ChallengeEvidence
> {
  readonly type: ChallengeType;
  readonly family: string;
  readonly maxDurationMs: number;
  readonly generator: ChallengeGenerator<TConfig>;
  readonly validator: ChallengeValidator<TConfig, TEvidence>;
  readonly scorer: ChallengeScorer<TConfig, TEvidence>;
}
