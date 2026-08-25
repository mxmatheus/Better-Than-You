import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_type.dart';
import 'reaction_generator.dart';
import 'reaction_scorer.dart';
import 'reaction_validator.dart';

final class ReactionDefinition
    implements ChallengeDefinition<ReactionConfig, ReactionEvidence> {
  const ReactionDefinition();

  @override
  ChallengeType get type => ChallengeType.reaction;

  @override
  String get name => 'REACTION';

  @override
  String get family => 'Visual Reaction';

  @override
  int get maxDurationMs => 5500; // 4.5s max wait + 1.0s input timeout

  @override
  ChallengeGenerator<ReactionConfig> get generator => const ReactionGenerator();

  @override
  ChallengeValidator<ReactionConfig, ReactionEvidence> get validator =>
      const ReactionValidator();

  @override
  ChallengeScorer<ReactionConfig, ReactionEvidence> get scorer =>
      const ReactionScorer();
}
