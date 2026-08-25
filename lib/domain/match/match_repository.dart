import '../challenge/challenge_evidence.dart';
import 'match_session.dart';
import 'round_result.dart';

abstract interface class MatchRepository {
  Future<MatchSession> createMatch({int? seed});
  Future<RoundResult> submitRoundEvidence({
    required MatchSession session,
    required ChallengeEvidence evidence,
  });
  Future<MatchSession> nextRound(MatchSession session);
}
