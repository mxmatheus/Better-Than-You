import '../challenge/challenge_type.dart';
import 'match_state.dart';
import 'round_result.dart';

final class MatchSession {
  final String matchId;
  final int matchSeed;
  final int totalRounds;
  final int targetWins;
  final int currentRoundIndex;
  final int playerWins;
  final int opponentWins;
  final List<RoundResult> history;
  final MatchLifecycleState state;
  final List<ChallengeType> scheduledChallenges;

  const MatchSession({
    required this.matchId,
    required this.matchSeed,
    this.totalRounds = 7,
    this.targetWins = 4,
    this.currentRoundIndex = 1,
    this.playerWins = 0,
    this.opponentWins = 0,
    this.history = const [],
    this.state = MatchLifecycleState.ready,
    required this.scheduledChallenges,
  });

  bool get isMatchOver =>
      playerWins >= targetWins ||
      opponentWins >= targetWins ||
      currentRoundIndex > totalRounds ||
      state == MatchLifecycleState.settled ||
      state == MatchLifecycleState.abandoned;

  RoundOutcome? get overallWinner {
    if (!isMatchOver) return null;
    if (playerWins > opponentWins) return RoundOutcome.win;
    if (opponentWins > playerWins) return RoundOutcome.loss;
    return RoundOutcome.draw;
  }

  ChallengeType get currentChallengeType {
    final index = (currentRoundIndex - 1) % scheduledChallenges.length;
    return scheduledChallenges[index];
  }

  int get currentRoundSeed =>
      (matchSeed + currentRoundIndex * 7919) & 0xFFFFFFFF;

  MatchSession copyWith({
    String? matchId,
    int? matchSeed,
    int? totalRounds,
    int? targetWins,
    int? currentRoundIndex,
    int? playerWins,
    int? opponentWins,
    List<RoundResult>? history,
    MatchLifecycleState? state,
    List<ChallengeType>? scheduledChallenges,
  }) {
    return MatchSession(
      matchId: matchId ?? this.matchId,
      matchSeed: matchSeed ?? this.matchSeed,
      totalRounds: totalRounds ?? this.totalRounds,
      targetWins: targetWins ?? this.targetWins,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      playerWins: playerWins ?? this.playerWins,
      opponentWins: opponentWins ?? this.opponentWins,
      history: history ?? this.history,
      state: state ?? this.state,
      scheduledChallenges: scheduledChallenges ?? this.scheduledChallenges,
    );
  }
}
