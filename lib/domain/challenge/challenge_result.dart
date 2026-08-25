import 'challenge_type.dart';

enum ValidationStatus {
  valid,
  flagged,
  forfeit,
  timeout,
  earlyFault,
  rejectedLate;

  bool get isScoring => this == valid || this == flagged;
}

final class ChallengeResult {
  final ChallengeType type;
  final int normalizedScore; // 0 - 1000
  final num rawMetric; // ms or correct count or distance
  final String formattedMetric; // e.g. "214 ms", "5 / 5", "98.4%"
  final ValidationStatus validationStatus;

  const ChallengeResult({
    required this.type,
    required this.normalizedScore,
    required this.rawMetric,
    required this.formattedMetric,
    this.validationStatus = ValidationStatus.valid,
  });
}
