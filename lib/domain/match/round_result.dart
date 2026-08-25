import '../challenge/challenge_result.dart';
import '../challenge/challenge_type.dart';
import 'match_state.dart';

final class RoundResult {
  final int roundIndex;
  final ChallengeType challengeType;
  final ChallengeResult playerResult;
  final ChallengeResult opponentResult;
  final RoundOutcome outcome;

  const RoundResult({
    required this.roundIndex,
    required this.challengeType,
    required this.playerResult,
    required this.opponentResult,
    required this.outcome,
  });

  static RoundOutcome determineOutcome(
    ChallengeResult player,
    ChallengeResult opponent,
  ) {
    if (player.normalizedScore > opponent.normalizedScore) {
      return RoundOutcome.win;
    } else if (player.normalizedScore < opponent.normalizedScore) {
      return RoundOutcome.loss;
    } else {
      return RoundOutcome.draw;
    }
  }
}
