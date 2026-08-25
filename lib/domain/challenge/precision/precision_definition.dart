import '../challenge_config.dart';
import '../challenge_contracts.dart';
import '../challenge_evidence.dart';
import '../challenge_type.dart';
import 'precision_generator.dart';
import 'precision_scorer.dart';
import 'precision_validator.dart';

final class PrecisionDefinition
    implements ChallengeDefinition<PrecisionConfig, PrecisionEvidence> {
  const PrecisionDefinition();

  @override
  ChallengeType get type => ChallengeType.precision;

  @override
  String get name => 'PRECISION';

  @override
  String get family => 'Target Accuracy';

  @override
  int get maxDurationMs => 1500; // 1.2s target lifetime + 300ms buffer

  @override
  ChallengeGenerator<PrecisionConfig> get generator =>
      const PrecisionGenerator();

  @override
  ChallengeValidator<PrecisionConfig, PrecisionEvidence> get validator =>
      const PrecisionValidator();

  @override
  ChallengeScorer<PrecisionConfig, PrecisionEvidence> get scorer =>
      const PrecisionScorer();
}
