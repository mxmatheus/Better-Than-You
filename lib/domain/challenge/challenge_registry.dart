import 'challenge_config.dart';
import 'challenge_contracts.dart';
import 'challenge_evidence.dart';
import 'challenge_type.dart';
import 'memory/memory_definition.dart';
import 'precision/precision_definition.dart';
import 'reaction/reaction_definition.dart';

final class ChallengeRegistry {
  static const Map<
    ChallengeType,
    ChallengeDefinition<ChallengeConfig, ChallengeEvidence>
  >
  _definitions = {
    ChallengeType.reaction: ReactionDefinition(),
    ChallengeType.memory: MemoryDefinition(),
    ChallengeType.precision: PrecisionDefinition(),
  };

  static ChallengeDefinition<ChallengeConfig, ChallengeEvidence> getDefinition(
    ChallengeType type,
  ) {
    final def = _definitions[type];
    if (def == null) {
      throw ArgumentError('Unregistered challenge type: $type');
    }
    return def;
  }

  static List<ChallengeDefinition<ChallengeConfig, ChallengeEvidence>>
  get allDefinitions => _definitions.values.toList();
}
