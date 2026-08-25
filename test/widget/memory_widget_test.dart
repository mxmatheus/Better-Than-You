import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_config.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/presentation/challenges/widgets/memory_challenge_widget.dart';

void main() {
  group('MemoryChallengeWidget Tests', () {
    testWidgets(
      'Renders 3x3 grid, plays back sequence, and accepts correct taps',
      (WidgetTester tester) async {
        MemoryEvidence? completedEvidence;

        const config = MemoryConfig(
          seed: 1337,
          sequenceLength: 3,
          sequence: [0, 4, 8],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MemoryChallengeWidget(
                config: config,
                onComplete: (evidence) => completedEvidence = evidence,
              ),
            ),
          ),
        );

        expect(find.text('GET READY'), findsOneWidget);

        // Prep (800ms) + 3 tiles * (400ms + 150ms) = 2450ms
        await tester.pump(const Duration(milliseconds: 2600));
        expect(find.text('REPRODUCE'), findsOneWidget);

        // Grid has 9 tiles
        final gridFinders = find.byType(GestureDetector);
        expect(gridFinders, findsWidgets);

        // Tap correct sequence: 0, then 4, then 8
        await tester.tap(gridFinders.at(0));
        await tester.pump(const Duration(milliseconds: 160));

        await tester.tap(gridFinders.at(4));
        await tester.pump(const Duration(milliseconds: 160));

        await tester.tap(gridFinders.at(8));
        await tester.pump(const Duration(milliseconds: 500));

        expect(completedEvidence, isNotNull);
        expect(completedEvidence!.correctCount, equals(3));
      },
    );
  });
}
