import 'challenge_type.dart';

sealed class ChallengeConfig {
  final ChallengeType type;
  final int seed;

  const ChallengeConfig({required this.type, required this.seed});
}

final class ReactionConfig extends ChallengeConfig {
  final int waitDelayMs;

  const ReactionConfig({required super.seed, required this.waitDelayMs})
    : super(type: ChallengeType.reaction);
}

final class MemoryConfig extends ChallengeConfig {
  final int sequenceLength;
  final List<int> sequence;

  const MemoryConfig({
    required super.seed,
    required this.sequenceLength,
    required this.sequence,
  }) : super(type: ChallengeType.memory);
}

final class PrecisionConfig extends ChallengeConfig {
  final double xTarget;
  final double yTarget;
  final double radiusNorm;
  final int durationMs;

  const PrecisionConfig({
    required super.seed,
    required this.xTarget,
    required this.yTarget,
    this.radiusNorm = 0.12,
    this.durationMs = 1200,
  }) : super(type: ChallengeType.precision);
}
