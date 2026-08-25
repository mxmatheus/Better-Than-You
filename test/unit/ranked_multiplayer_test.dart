import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/utils/elo_calculator.dart';
import 'package:better_than_you/core/utils/mulberry32.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/domain/challenge/challenge_registry.dart';
import 'package:better_than_you/domain/challenge/challenge_type.dart';
import 'package:better_than_you/domain/match/match_session.dart';
import 'package:better_than_you/domain/match/match_state.dart';
import 'package:better_than_you/domain/match/round_result.dart';

void main() {
  group('Ranked Multiplayer & Server Authority Integration Tests', () {
    test(
      'Shared match seed generates identical 7 rounds for both Player A and Player B',
      () {
        const serverMatchSeed = 314159265;
        final prngA = Mulberry32(serverMatchSeed);
        final prngB = Mulberry32(serverMatchSeed);

        final roundsA = <int>[];
        final roundsB = <int>[];

        for (var i = 1; i <= 7; i++) {
          roundsA.add(prngA.nextUint32());
          roundsB.add(prngB.nextUint32());
        }

        expect(roundsA, equals(roundsB));
        expect(roundsA.length, equals(7));
        expect(roundsA[0], equals(1158041355));
        expect(roundsA[1], equals(2101024409));
      },
    );

    test(
      'Authoritative Round Resolution: Higher score wins, equal score draws',
      () {
        final def = ChallengeRegistry.getDefinition(ChallengeType.reaction);
        final config = def.generator.generate(1337);

        // Player A reacts in 210ms (score = 941)
        final subA = def.scorer.score(
          config,
          const ReactionEvidence(
            clientTimestampMonoMs: 210,
            reactionTimeMs: 210,
            isFault: false,
            triggerRenderedMonoMs: 0,
            touchDownMonoMs: 210,
          ),
        );

        // Player B reacts in 320ms (score = 732)
        final subB = def.scorer.score(
          config,
          const ReactionEvidence(
            clientTimestampMonoMs: 320,
            reactionTimeMs: 320,
            isFault: false,
            triggerRenderedMonoMs: 0,
            touchDownMonoMs: 320,
          ),
        );

        final outcomeA = RoundResult.determineOutcome(subA, subB);
        expect(outcomeA, equals(RoundOutcome.win));

        final outcomeB = RoundResult.determineOutcome(subB, subA);
        expect(outcomeB, equals(RoundOutcome.loss));

        // Draw scenario (identical reaction)
        final drawOutcome = RoundResult.determineOutcome(subA, subA);
        expect(drawOutcome, equals(RoundOutcome.draw));
      },
    );

    test(
      'Early Match Termination: Match finishes immediately when 4 wins are reached',
      () {
        var session = const MatchSession(
          matchId: 'live_match_test_001',
          matchSeed: 1337,
          totalRounds: 7,
          targetWins: 4,
          scheduledChallenges: [
            ChallengeType.reaction,
            ChallengeType.precision,
            ChallengeType.memory,
            ChallengeType.reaction,
            ChallengeType.precision,
            ChallengeType.memory,
            ChallengeType.reaction,
          ],
        );

        expect(session.isMatchOver, isFalse);

        // Player wins 4 rounds in a row
        session = session.copyWith(playerWins: 4, currentRoundIndex: 5);
        expect(session.isMatchOver, isTrue);
        expect(session.overallWinner, equals(RoundOutcome.win));
      },
    );

    test(
      'Idempotent Elo Settlement: Consecutive settlements do not apply duplicate rating changes',
      () {
        var playerAMmr = 1000;
        var playerBMmr = 1000;
        var isSettled = false;

        void settleMatch() {
          if (isSettled) return; // Idempotency guard

          final res = EloCalculator.calculateDeltas(
            mmrA: playerAMmr,
            mmrB: playerBMmr,
            provisionalRemainingA: 10,
            provisionalRemainingB: 10,
            scoreA: 1.0,
          );

          playerAMmr += res.deltaA;
          playerBMmr += res.deltaB;
          isSettled = true;
        }

        // First call
        settleMatch();
        expect(playerAMmr, equals(1025));
        expect(playerBMmr, equals(975));

        // Repeated calls (simulating duplicate triggers/reconnects)
        settleMatch();
        settleMatch();
        settleMatch();

        expect(playerAMmr, equals(1025));
        expect(playerBMmr, equals(975));
      },
    );
  });
}
