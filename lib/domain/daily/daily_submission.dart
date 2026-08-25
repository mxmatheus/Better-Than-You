enum DailyAttemptStatus {
  inProgress,
  completed;

  static DailyAttemptStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return DailyAttemptStatus.completed;
      default:
        return DailyAttemptStatus.inProgress;
    }
  }
}

final class DailySubmission {
  final DateTime challengeDate;
  final String userId;
  final DailyAttemptStatus status;
  final int currentRoundIndex;
  final int totalScore;
  final List<int> roundScores;
  final DateTime? completedAt;

  const DailySubmission({
    required this.challengeDate,
    required this.userId,
    required this.status,
    required this.currentRoundIndex,
    required this.totalScore,
    required this.roundScores,
    this.completedAt,
  });

  bool get isCompleted => status == DailyAttemptStatus.completed;

  DailySubmission copyWith({
    DailyAttemptStatus? status,
    int? currentRoundIndex,
    int? totalScore,
    List<int>? roundScores,
    DateTime? completedAt,
  }) {
    return DailySubmission(
      challengeDate: challengeDate,
      userId: userId,
      status: status ?? this.status,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      totalScore: totalScore ?? this.totalScore,
      roundScores: roundScores ?? this.roundScores,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
