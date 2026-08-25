import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/match/mock_match_repository.dart';
import 'package:better_than_you/presentation/match/match_screen.dart';
import 'package:better_than_you/presentation/match/widgets/match_hud.dart';
import 'package:better_than_you/presentation/match/widgets/split_comparison_card.dart';

void main() {
  group('Local Demo Match Flow Tests', () {
    testWidgets('Initializes Round 1, completes reaction, reveals Split Card, and advances',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MatchScreen(
            repository: MockMatchRepository(),
            matchSeed: 7777,
          ),
        ),
      );

      // Pump to finish match init
      await tester.pump();
      await tester.pump();

      // HUD renders Round 1 / 7
      expect(find.byType(MatchHud), findsOneWidget);
      expect(find.text('ROUND 1 / 7'), findsOneWidget);

      // Advance reaction challenge prep (800ms) + wait (prng delay) -> trigger
      await tester.pump(const Duration(milliseconds: 4600));

      // Tap to complete reaction
      await tester.tap(find.byType(MatchScreen));
      await tester.pump();

      // Split card overlay appears
      expect(find.byType(SplitComparisonCard), findsOneWidget);

      // Advance animation choreography to reveal continue button (3500ms)
      await tester.pump(const Duration(milliseconds: 3500));

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump();

      // Advances to Round 2 / 7 (Precision)
      expect(find.text('ROUND 2 / 7'), findsOneWidget);
      expect(find.byType(SplitComparisonCard), findsNothing);
    });
  });
}
