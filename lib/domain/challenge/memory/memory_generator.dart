import '../../../core/utils/mulberry32.dart';
import '../challenge_config.dart';
import '../challenge_contracts.dart';

final class MemoryGenerator implements ChallengeGenerator<MemoryConfig> {
  const MemoryGenerator();

  @override
  MemoryConfig generate(int seed, {Map<String, dynamic>? options}) {
    final length = (options?['sequenceLength'] as int?) ?? 5;
    final prng = Mulberry32(seed);

    final sequence = <int>[];
    var previousTile = -1;

    for (var i = 0; i < length; i++) {
      int nextTile;
      if (previousTile == -1) {
        nextTile = prng.nextInt(0, 8);
      } else {
        // Pick from 8 remaining possibilities to ensure no consecutive duplicate
        final pick = prng.nextInt(0, 7);
        nextTile = pick >= previousTile ? pick + 1 : pick;
      }
      sequence.add(nextTile);
      previousTile = nextTile;
    }

    return MemoryConfig(
      seed: seed,
      sequenceLength: length,
      sequence: List.unmodifiable(sequence),
    );
  }
}
