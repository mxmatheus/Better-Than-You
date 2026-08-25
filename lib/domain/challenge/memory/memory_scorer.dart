import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_result.dart';
import '../challenge_type.dart';
import 'memory_validator.dart';

final class MemoryScorer
    implements ChallengeScorer<MemoryConfig, MemoryEvidence> {
  final MemoryValidator _validator;

  const MemoryScorer([this._validator = const MemoryValidator()]);

  @override
  ChallengeResult score(
    MemoryConfig config,
    MemoryEvidence evidence, {
    ValidationStatus? statusOverride,
  }) {
    final status = statusOverride ?? _validator.validate(config, evidence);
    final k = evidence.correctCount;
    final l = config.sequenceLength;

    if (!status.isScoring || k <= 0) {
      return ChallengeResult(
        type: ChallengeType.memory,
        normalizedScore: 0,
        rawMetric: k,
        formattedMetric: '$k / $l',
        validationStatus: status,
      );
    }

    int score;
    if (k < l) {
      score = ((750.0 * k) / l).round();
    } else {
      // Full sequence reproduced (k == l)
      final t = evidence.completionTimeMs.clamp(0, 6000);
      final speedFactor = (1.0 - (t / 6000.0)).clamp(0.0, 1.0);
      final speedBonus = (250.0 * speedFactor).round();
      score = (750 + speedBonus).clamp(0, 1000);
    }

    return ChallengeResult(
      type: ChallengeType.memory,
      normalizedScore: score,
      rawMetric: k,
      formattedMetric: '$k / $l',
      validationStatus: status,
    );
  }
}
