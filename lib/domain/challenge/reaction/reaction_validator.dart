import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_result.dart';

final class ReactionValidator
    implements ChallengeValidator<ReactionConfig, ReactionEvidence> {
  const ReactionValidator();

  @override
  ValidationStatus validate(ReactionConfig config, ReactionEvidence evidence) {
    if (evidence.isFault || evidence.reactionTimeMs < 100) {
      return ValidationStatus.earlyFault;
    }
    if (evidence.reactionTimeMs > 1000) {
      return ValidationStatus.timeout;
    }
    return ValidationStatus.valid;
  }
}
