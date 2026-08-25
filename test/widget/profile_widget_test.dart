import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/routing/app_router.dart';
import 'package:better_than_you/core/theme/app_theme.dart';
import 'package:better_than_you/domain/auth/auth_state.dart';
import 'package:better_than_you/domain/auth/auth_user.dart';
import 'package:better_than_you/domain/auth/local_auth_repository.dart';
import 'package:better_than_you/domain/profile/player_profile.dart';
import 'package:better_than_you/presentation/profile/profile_screen.dart';
import 'package:better_than_you/presentation/shell/app_shell.dart';

void main() {
  group('ProfileScreen & AppShell Widget Tests', () {
    testWidgets('ProfileScreen renders identity, MMR, rank badge, and stats', (tester) async {
      const profile = PlayerProfile(
        id: 'user_123',
        username: 'ApexReflex',
        displayName: 'Apex Master',
        mmr: 1250,
        matchesPlayed: 20,
        wins: 15,
        losses: 4,
        draws: 1,
        reactionAverage: 850,
        memoryAverage: 700,
        precisionAverage: 900,
      );

      final repo = LocalAuthRepository(
        initialState: const AuthAuthenticated(
          user: AuthUser(id: 'user_123', email: 'apex@example.com'),
          profile: profile,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProfileScreen(
            authRepository: repo,
            initialProfile: profile,
          ),
        ),
      );

      expect(find.text('Apex Master'), findsOneWidget);
      expect(find.text('@ApexReflex'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('MMR'), findsOneWidget);
      expect(find.text('MATCH RECORD'), findsOneWidget);
      expect(find.text('15'), findsOneWidget); // wins
      expect(find.text('4'), findsOneWidget); // losses
      expect(find.text('75.0%'), findsOneWidget); // win rate
      expect(find.text('LOGOUT'), findsOneWidget);
    });

    testWidgets('ProfileScreen logout button signs out and removes navigation stack', (tester) async {
      const profile = PlayerProfile(
        id: 'user_123',
        username: 'ApexReflex',
        displayName: 'Apex Master',
        mmr: 1000,
      );

      final repo = LocalAuthRepository(
        initialState: const AuthAuthenticated(
          user: AuthUser(id: 'user_123', email: 'apex@example.com'),
          profile: profile,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProfileScreen(
            authRepository: repo,
            initialProfile: profile,
          ),
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('LOGIN_SCREEN')),
          },
        ),
      );

      await tester.tap(find.text('LOGOUT'));
      await tester.pumpAndSettle();

      expect(repo.currentState.isAuthenticated, isFalse);
      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    });

    testWidgets('AppShell renders bottom navigation bar and switches tabs', (tester) async {
      final repo = LocalAuthRepository(
        initialState: const AuthAuthenticated(
          user: AuthUser(id: 'user_1', email: 'test@example.com'),
          profile: PlayerProfile(id: 'user_1', username: 'Champion', mmr: 1000),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppShell(authRepository: repo),
        ),
      );

      // Tab 0: Arena / Home
      expect(find.text('RANKED 1V1'), findsOneWidget);

      // Tap Tab 1: Daily
      await tester.tap(find.text('DAILY'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY CHALLENGE'), findsWidgets);

      // Tap Tab 2: Profile
      await tester.tap(find.text('PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('MATCH RECORD'), findsOneWidget);
    });
  });
}
