import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_config.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/presentation/challenges/widgets/reaction_challenge_widget.dart';

void main() {
  group('ReactionChallengeWidget Tests', () {
    testWidgets('Renders preparation and responds to early tap with fault',
        (WidgetTester tester) async {
      ReactionEvidence? completedEvidence;

      const config = ReactionConfig(
        seed: 1337,
        waitDelayMs: 3000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionChallengeWidget(
              config: config,
              onComplete: (evidence) => completedEvidence = evidence,
            ),
          ),
        ),
      );

      // Initial state is GET READY
      expect(find.text('GET READY'), findsOneWidget);

      // Advance 850ms to reach WAIT...
      await tester.pump(const Duration(milliseconds: 850));
      expect(find.text('WAIT...'), findsOneWidget);

      // Tap early while waiting
      await tester.tap(find.byType(ReactionChallengeWidget));
      await tester.pump();

      expect(find.text('TOO EARLY!'), findsOneWidget);
      expect(completedEvidence, isNotNull);
      expect(completedEvidence!.isFault, isTrue);
    });

    testWidgets('Triggers GO state and records reaction time on tap',
        (WidgetTester tester) async {
      ReactionEvidence? completedEvidence;
      var simulatedMonoMs = 1000;

      const config = ReactionConfig(
        seed: 1337,
        waitDelayMs: 1500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionChallengeWidget(
              config: config,
              clockMonoMs: () => simulatedMonoMs,
              onComplete: (evidence) => completedEvidence = evidence,
            ),
          ),
        ),
      );

      // Advance prep (800ms) + wait (1500ms) = 2300ms
      await tester.pump(const Duration(milliseconds: 2350));
      expect(find.text('TAP!'), findsOneWidget);

      // Simulate 220ms reaction delay
      simulatedMonoMs += 220;
      await tester.pump(const Duration(milliseconds: 220));
      await tester.tap(find.byType(ReactionChallengeWidget));
      await tester.pump();

      expect(completedEvidence, isNotNull);
      expect(completedEvidence!.isFault, isFalse);
      expect(completedEvidence!.reactionTimeMs, equals(220));
    });
  });
}
