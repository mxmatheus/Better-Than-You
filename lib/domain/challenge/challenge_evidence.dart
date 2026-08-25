import 'challenge_type.dart';

sealed class ChallengeEvidence {
  final ChallengeType type;
  final int clientTimestampMonoMs;

  const ChallengeEvidence({
    required this.type,
    required this.clientTimestampMonoMs,
  });

  Map<String, dynamic> toJson();
}

final class ReactionEvidence extends ChallengeEvidence {
  final int reactionTimeMs;
  final bool isFault;
  final int triggerRenderedMonoMs;
  final int touchDownMonoMs;

  const ReactionEvidence({
    required super.clientTimestampMonoMs,
    required this.reactionTimeMs,
    required this.isFault,
    required this.triggerRenderedMonoMs,
    required this.touchDownMonoMs,
  }) : super(type: ChallengeType.reaction);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'clientTimestampMonoMs': clientTimestampMonoMs,
        'reactionTimeMs': reactionTimeMs,
        'isFault': isFault,
        'triggerRenderedMonoMs': triggerRenderedMonoMs,
        'touchDownMonoMs': touchDownMonoMs,
      };
}

final class MemoryEvidence extends ChallengeEvidence {
  final int correctCount;
  final int sequenceLength;
  final int completionTimeMs;
  final List<Map<String, dynamic>> rawTaps;

  const MemoryEvidence({
    required super.clientTimestampMonoMs,
    required this.correctCount,
    required this.sequenceLength,
    required this.completionTimeMs,
    required this.rawTaps,
  }) : super(type: ChallengeType.memory);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'clientTimestampMonoMs': clientTimestampMonoMs,
        'correctCount': correctCount,
        'sequenceLength': sequenceLength,
        'completionTimeMs': completionTimeMs,
        'rawTaps': rawTaps,
      };
}

final class PrecisionEvidence extends ChallengeEvidence {
  final double xTouch;
  final double yTouch;
  final int timeToTapMs;
  final double distanceError;

  const PrecisionEvidence({
    required super.clientTimestampMonoMs,
    required this.xTouch,
    required this.yTouch,
    required this.timeToTapMs,
    required this.distanceError,
  }) : super(type: ChallengeType.precision);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'clientTimestampMonoMs': clientTimestampMonoMs,
        'xTouch': xTouch,
        'yTouch': yTouch,
        'timeToTapMs': timeToTapMs,
        'distanceError': distanceError,
      };
}
