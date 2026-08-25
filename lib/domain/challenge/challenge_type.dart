enum ChallengeType {
  reaction,
  memory,
  precision;

  String get displayName {
    switch (this) {
      case ChallengeType.reaction:
        return 'REACTION';
      case ChallengeType.memory:
        return 'MEMORY';
      case ChallengeType.precision:
        return 'PRECISION';
    }
  }

  String get subtitle {
    switch (this) {
      case ChallengeType.reaction:
        return 'Visual trigger reflex test';
      case ChallengeType.memory:
        return 'Spatial sequence reproduction';
      case ChallengeType.precision:
        return 'Target accuracy under pressure';
    }
  }

  static ChallengeType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MEMORY':
        return ChallengeType.memory;
      case 'PRECISION':
        return ChallengeType.precision;
      default:
        return ChallengeType.reaction;
    }
  }
}
