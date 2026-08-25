import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_result.dart';

final class PrecisionValidator
    implements ChallengeValidator<PrecisionConfig, PrecisionEvidence> {
  const PrecisionValidator();

  @override
  ValidationStatus validate(
    PrecisionConfig config,
    PrecisionEvidence evidence,
  ) {
    if (evidence.xTouch < 0.0 ||
        evidence.xTouch > 1.0 ||
        evidence.yTouch < 0.0 ||
        evidence.yTouch > 1.0) {
      return ValidationStatus.flagged;
    }
    if (evidence.timeToTapMs < 0 || evidence.timeToTapMs > 2000) {
      return ValidationStatus.timeout;
    }
    return ValidationStatus.valid;
  }
}
