import 'dart:math' as math;
import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_result.dart';
import '../challenge_type.dart';
import 'reaction_validator.dart';

final class ReactionScorer
    implements ChallengeScorer<ReactionConfig, ReactionEvidence> {
  final ReactionValidator _validator;

  const ReactionScorer([this._validator = const ReactionValidator()]);

  @override
  ChallengeResult score(
    ReactionConfig config,
    ReactionEvidence evidence, {
    ValidationStatus? statusOverride,
  }) {
    final status = statusOverride ?? _validator.validate(config, evidence);

    if (!status.isScoring ||
        evidence.reactionTimeMs < 100 ||
        evidence.reactionTimeMs > 600) {
      final formatted = status == ValidationStatus.earlyFault
          ? 'FAULT'
          : (status == ValidationStatus.timeout ? 'TIMEOUT' : '${evidence.reactionTimeMs} ms');
      return ChallengeResult(
        type: ChallengeType.reaction,
        normalizedScore: 0,
        rawMetric: evidence.reactionTimeMs,
        formattedMetric: formatted,
        validationStatus: status,
      );
    }

    final t = evidence.reactionTimeMs;
    int score;
    if (t <= 160) {
      score = 1000;
    } else {
      final ratio = (t - 160) / 440.0;
      final rawScore = 1000.0 * (1.0 - math.pow(ratio, 1.3));
      score = rawScore.round().clamp(0, 1000);
    }

    return ChallengeResult(
      type: ChallengeType.reaction,
      normalizedScore: score,
      rawMetric: t,
      formattedMetric: '$t ms',
      validationStatus: status,
    );
  }
}
