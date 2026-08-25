import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_type.dart';
import 'memory_generator.dart';
import 'memory_scorer.dart';
import 'memory_validator.dart';

final class MemoryDefinition
    implements ChallengeDefinition<MemoryConfig, MemoryEvidence> {
  const MemoryDefinition();

  @override
  ChallengeType get type => ChallengeType.memory;

  @override
  String get name => 'MEMORY';

  @override
  String get family => 'Spatial Memory';

  @override
  int get maxDurationMs => 9000; // ~3.0s presentation + 6.0s input

  @override
  ChallengeGenerator<MemoryConfig> get generator => const MemoryGenerator();

  @override
  ChallengeValidator<MemoryConfig, MemoryEvidence> get validator =>
      const MemoryValidator();

  @override
  ChallengeScorer<MemoryConfig, MemoryEvidence> get scorer =>
      const MemoryScorer();
}
