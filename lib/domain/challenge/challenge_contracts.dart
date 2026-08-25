import 'challenge_config.dart';
import 'challenge_evidence.dart';
import 'challenge_result.dart';
import 'challenge_type.dart';

/// Pure metadata contract defining challenge characteristics.
abstract interface class ChallengeDefinition<C extends ChallengeConfig,
    E extends ChallengeEvidence> {
  ChallengeType get type;
  String get name;
  String get family;
  int get maxDurationMs;

  ChallengeGenerator<C> get generator;
  ChallengeValidator<C, E> get validator;
  ChallengeScorer<C, E> get scorer;
}

/// Pure deterministic generator mapping seed into challenge configuration.
abstract interface class ChallengeGenerator<C extends ChallengeConfig> {
  C generate(int seed, {Map<String, dynamic>? options});
}

/// Pure validator checking evidence structural and physical integrity.
abstract interface class ChallengeValidator<C extends ChallengeConfig,
    E extends ChallengeEvidence> {
  ValidationStatus validate(C config, E evidence);
}

/// Pure mathematical scorer converting evidence to normalized 0-1000 score.
abstract interface class ChallengeScorer<C extends ChallengeConfig,
    E extends ChallengeEvidence> {
  ChallengeResult score(C config, E evidence, {ValidationStatus? statusOverride});
}

/// Abstract runtime representing the lifecycle of interactive execution state.
abstract interface class ChallengeRuntime<C extends ChallengeConfig,
    E extends ChallengeEvidence> {
  C get config;
  bool get isCompleted;
  void start();
  E complete();
}
