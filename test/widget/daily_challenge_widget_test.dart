import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/theme/app_theme.dart';
import 'package:better_than_you/domain/daily/local_daily_challenge_repository.dart';
import 'package:better_than_you/presentation/daily/daily_challenge_screen.dart';
import 'package:better_than_you/presentation/daily/daily_leaderboard_screen.dart';

void main() {
  group('Daily Challenge & Leaderboard Widget Tests', () {
    testWidgets('DailyChallengeScreen renders preparation view and round HUD', (tester) async {
      final repo = LocalDailyChallengeRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: DailyChallengeScreen(repository: repo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
      expect(find.text('ROUND 1 / 10'), findsOneWidget);
      expect(find.text('SCORE: 0'), findsOneWidget);
      expect(find.text('START ROUND 1'), findsOneWidget);
    });

    testWidgets('DailyLeaderboardScreen renders score, rank, nearby list, and countdown', (tester) async {
      final repo = LocalDailyChallengeRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: DailyLeaderboardScreen(repository: repo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GLOBAL LEADERBOARD'), findsOneWidget);
      expect(find.text("TODAY'S SCORE"), findsOneWidget);
      expect(find.text('GLOBAL RANK'), findsOneWidget);
      expect(find.text('TOP PERCENTILE'), findsOneWidget);
      expect(find.text('NEXT CHALLENGE'), findsOneWidget);
      expect(find.text('RETURN HOME'), findsOneWidget);
    });
  });
}
