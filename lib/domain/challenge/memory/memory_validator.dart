import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_result.dart';

final class MemoryValidator
    implements ChallengeValidator<MemoryConfig, MemoryEvidence> {
  const MemoryValidator();

  @override
  ValidationStatus validate(MemoryConfig config, MemoryEvidence evidence) {
    if (evidence.sequenceLength != config.sequenceLength) {
      return ValidationStatus.flagged;
    }
    if (evidence.correctCount < 0 ||
        evidence.correctCount > config.sequenceLength) {
      return ValidationStatus.flagged;
    }
    if (evidence.completionTimeMs > 10000) {
      return ValidationStatus.timeout;
    }
    return ValidationStatus.valid;
  }
}
