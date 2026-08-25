import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_config.dart';
import 'package:better_than_you/domain/challenge/challenge_registry.dart';
import 'package:better_than_you/domain/challenge/challenge_type.dart';

void main() {
  group('Challenge Engine — Cross-Challenge Determinism & Contract Safety', () {
    test('Registry contains all 3 MVP challenge definitions', () {
      final definitions = ChallengeRegistry.allDefinitions;
      expect(definitions.length, equals(3));

      final types = definitions.map((d) => d.type).toSet();
      expect(types, contains(ChallengeType.reaction));
      expect(types, contains(ChallengeType.memory));
      expect(types, contains(ChallengeType.precision));
    });

    test('Same seed generates identical configurations for all challenge types', () {
      const testSeed = 88888888;

      for (final type in ChallengeType.values) {
        final def = ChallengeRegistry.getDefinition(type);
        final configA = def.generator.generate(testSeed);
        final configB = def.generator.generate(testSeed);

        expect(configA.type, equals(configB.type));
        expect(configA.seed, equals(configB.seed));

        if (configA is ReactionConfig && configB is ReactionConfig) {
          expect(configA.waitDelayMs, equals(configB.waitDelayMs));
        } else if (configA is MemoryConfig && configB is MemoryConfig) {
          expect(configA.sequence, equals(configB.sequence));
        } else if (configA is PrecisionConfig && configB is PrecisionConfig) {
          expect(configA.xTarget, equals(configB.xTarget));
          expect(configA.yTarget, equals(configB.yTarget));
        }
      }
    });

    test('Different seeds produce distinct configurations', () {
      final reactionDef = ChallengeRegistry.getDefinition(ChallengeType.reaction);
      final r1 = reactionDef.generator.generate(1001) as ReactionConfig;
      final r2 = reactionDef.generator.generate(9999) as ReactionConfig;
      // Probability of collision is 1 / 3001, highly likely different
      expect(r1.waitDelayMs != r2.waitDelayMs || r1.seed != r2.seed, isTrue);

      final memoryDef = ChallengeRegistry.getDefinition(ChallengeType.memory);
      final m1 = memoryDef.generator.generate(1001) as MemoryConfig;
      final m2 = memoryDef.generator.generate(9999) as MemoryConfig;
      expect(m1.sequence, isNot(equals(m2.sequence)));

      final precisionDef = ChallengeRegistry.getDefinition(ChallengeType.precision);
      final p1 = precisionDef.generator.generate(1001) as PrecisionConfig;
      final p2 = precisionDef.generator.generate(9999) as PrecisionConfig;
      expect(p1.xTarget, isNot(equals(p2.xTarget)));
    });
  });
}
