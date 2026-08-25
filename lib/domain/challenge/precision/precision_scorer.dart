import 'dart:math' as math;
import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_result.dart';
import '../challenge_type.dart';
import 'precision_validator.dart';

final class PrecisionScorer
    implements ChallengeScorer<PrecisionConfig, PrecisionEvidence> {
  final PrecisionValidator _validator;

  const PrecisionScorer([this._validator = const PrecisionValidator()]);

  @override
  ChallengeResult score(
    PrecisionConfig config,
    PrecisionEvidence evidence, {
    ValidationStatus? statusOverride,
  }) {
    final status = statusOverride ?? _validator.validate(config, evidence);

    final dx = evidence.xTouch - config.xTarget;
    final dy = evidence.yTouch - config.yTarget;
    final distance = math.sqrt(dx * dx + dy * dy);
    final rNorm = config.radiusNorm;

    if (!status.isScoring ||
        distance > rNorm ||
        evidence.timeToTapMs < 0 ||
        evidence.timeToTapMs > config.durationMs) {
      final formatted = evidence.timeToTapMs > config.durationMs
          ? 'TIMEOUT'
          : (distance > rNorm ? 'MISS' : '0%');
      return ChallengeResult(
        type: ChallengeType.precision,
        normalizedScore: 0,
        rawMetric: distance,
        formattedMetric: formatted,
        validationStatus: status,
      );
    }

    final accuracyRatio = (1.0 - (distance / rNorm)).clamp(0.0, 1.0);
    final distScore = 850.0 * math.pow(accuracyRatio, 1.5);
    final speedFactor = (1.0 - (evidence.timeToTapMs / config.durationMs)).clamp(0.0, 1.0);
    final speedScore = 150.0 * speedFactor;

    final score = (distScore + speedScore).round().clamp(0, 1000);
    final accuracyPercent = (accuracyRatio * 100.0).toStringAsFixed(1);

    return ChallengeResult(
      type: ChallengeType.precision,
      normalizedScore: score,
      rawMetric: distance,
      formattedMetric: '$accuracyPercent%',
      validationStatus: status,
    );
  }
}
