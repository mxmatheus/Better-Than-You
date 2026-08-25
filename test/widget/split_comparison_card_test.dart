import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_result.dart';
import 'package:better_than_you/domain/challenge/challenge_type.dart';
import 'package:better_than_you/domain/match/match_state.dart';
import 'package:better_than_you/domain/match/round_result.dart';
import 'package:better_than_you/presentation/match/widgets/split_comparison_card.dart';

void main() {
  group('SplitComparisonCard Animation Choreography Tests', () {
    testWidgets('Unfolds choreography and enables continue button',
        (WidgetTester tester) async {
      var continueTapped = false;

      const roundResult = RoundResult(
        roundIndex: 1,
        challengeType: ChallengeType.reaction,
        playerResult: ChallengeResult(
          type: ChallengeType.reaction,
          normalizedScore: 842,
          rawMetric: 214,
          formattedMetric: '214 ms',
        ),
        opponentResult: ChallengeResult(
          type: ChallengeType.reaction,
          normalizedScore: 710,
          rawMetric: 249,
          formattedMetric: '249 ms',
        ),
        outcome: RoundOutcome.win,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitComparisonCard(
              roundResult: roundResult,
              onContinue: () => continueTapped = true,
            ),
          ),
        ),
      );

      // Initially card is mounted
      expect(find.text('ROUND 1'), findsOneWidget);
      expect(find.text('REACTION'), findsOneWidget);

      // t = 0.4s: YOU section reveals
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('214 ms'), findsOneWidget);

      // t = 1.2s: Opponent section reveals
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('249 ms'), findsOneWidget);

      // t = 2.4s: Outcome banner appears
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('YOU WIN'), findsOneWidget);

      // t = 3.2s: Continue button is active
      await tester.pump(const Duration(milliseconds: 800));
      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();

      expect(continueTapped, isTrue);
    });
  });
}
