import '../../../core/utils/mulberry32.dart';
import '../challenge_config.dart';
import '../challenge_contracts.dart';

final class PrecisionGenerator implements ChallengeGenerator<PrecisionConfig> {
  const PrecisionGenerator();

  @override
  PrecisionConfig generate(int seed, {Map<String, dynamic>? options}) {
    final prng = Mulberry32(seed);
    final x = 0.18 + prng.nextFloat() * 0.64;
    final y = 0.18 + prng.nextFloat() * 0.64;

    return PrecisionConfig(
      seed: seed,
      xTarget: x,
      yTarget: y,
      radiusNorm: 0.12,
      durationMs: 1200,
    );
  }
}
