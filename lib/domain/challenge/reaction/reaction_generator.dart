import '../../../core/utils/mulberry32.dart';
import '../challenge_config.dart';
import '../challenge_contracts.dart';

final class ReactionGenerator implements ChallengeGenerator<ReactionConfig> {
  const ReactionGenerator();

  @override
  ReactionConfig generate(int seed, {Map<String, dynamic>? options}) {
    final prng = Mulberry32(seed);
    final waitDelayMs = prng.nextInt(1500, 4500);
    return ReactionConfig(
      seed: seed,
      waitDelayMs: waitDelayMs,
    );
  }
}
