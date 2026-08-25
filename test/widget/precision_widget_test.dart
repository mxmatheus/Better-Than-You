import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/challenge/challenge_config.dart';
import 'package:better_than_you/domain/challenge/challenge_evidence.dart';
import 'package:better_than_you/presentation/challenges/widgets/precision_challenge_widget.dart';

void main() {
  group('PrecisionChallengeWidget Tests', () {
    testWidgets('Renders 1:1 arena, animates target and captures tap coordinates',
        (WidgetTester tester) async {
      PrecisionEvidence? completedEvidence;

      const config = PrecisionConfig(
        seed: 1337,
        xTarget: 0.5,
        yTarget: 0.5,
        radiusNorm: 0.12,
        durationMs: 1200,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrecisionChallengeWidget(
              config: config,
              onComplete: (evidence) => completedEvidence = evidence,
            ),
          ),
        ),
      );

      expect(find.text('GET READY'), findsOneWidget);

      // Advance 850ms to activate target
      await tester.pump(const Duration(milliseconds: 850));
      expect(find.text('TAP TARGET'), findsOneWidget);

      // Tap exact center of the precision arena
      final arenaFinder = find.byKey(const Key('precision_arena'));
      final centerPoint = tester.getCenter(arenaFinder);
      await tester.tapAt(centerPoint);
      await tester.pump(const Duration(milliseconds: 400));

      expect(completedEvidence, isNotNull);
      expect(completedEvidence!.distanceError, lessThan(0.01));
    });
  });
}
