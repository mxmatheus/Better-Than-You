import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/routing/app_router.dart';
import 'package:better_than_you/core/theme/app_theme.dart';
import 'package:better_than_you/domain/auth/auth_state.dart';
import 'package:better_than_you/domain/auth/auth_user.dart';
import 'package:better_than_you/domain/auth/local_auth_repository.dart';
import 'package:better_than_you/domain/profile/player_profile.dart';
import 'package:better_than_you/presentation/home/home_screen.dart';
import 'package:better_than_you/presentation/profile/profile_screen.dart';
import 'package:better_than_you/presentation/shell/app_shell.dart';
import 'package:better_than_you/presentation/shell/widgets/pill_bottom_navigation_bar.dart';

void main() {
  group('ProfileScreen & AppShell Widget Tests', () {
    testWidgets('ProfileScreen renders identity, MMR, rank badge, and stats', (
      tester,
    ) async {
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
          home: ProfileScreen(authRepository: repo, initialProfile: profile),
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

    testWidgets(
      'HomeScreen renders authenticated player displayName in top bar',
      (tester) async {
        const profile = PlayerProfile(
          id: 'user_123',
          username: 'batuhan',
          displayName: 'Batuhan',
          mmr: 1100,
        );

        final repo = LocalAuthRepository(
          initialState: const AuthAuthenticated(
            user: AuthUser(id: 'user_123', email: 'batuhan@example.com'),
            profile: profile,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: HomeScreen(authRepository: repo),
          ),
        );

        expect(find.text('Batuhan'), findsOneWidget);
        expect(find.text('1100 MMR'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen logout button signs out and removes navigation stack',
      (tester) async {
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
            home: ProfileScreen(authRepository: repo, initialProfile: profile),
            routes: {
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text('LOGIN_SCREEN')),
            },
          ),
        );

        await tester.tap(find.text('LOGOUT'));
        await tester.pumpAndSettle();

        expect(repo.currentState.isAuthenticated, isFalse);
        expect(find.text('LOGIN_SCREEN'), findsOneWidget);
      },
    );

    testWidgets('AppShell renders PillBottomNavigationBar and switches tabs', (
      tester,
    ) async {
      const profile = PlayerProfile(
        id: 'user_1',
        username: 'batuhan',
        displayName: 'Batuhan',
        mmr: 1000,
      );

      final repo = LocalAuthRepository(
        initialState: const AuthAuthenticated(
          user: AuthUser(id: 'user_1', email: 'batuhan@example.com'),
          profile: profile,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppShell(authRepository: repo),
        ),
      );

      expect(find.byType(PillBottomNavigationBar), findsOneWidget);

      // Tab 0: Arena / Home displays Batuhan
      expect(find.text('Batuhan'), findsOneWidget);
      expect(find.text('RANKED 1V1'), findsOneWidget);

      // Tap Tab 1: Daily
      await tester.tap(find.text('DAILY'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY CHALLENGE'), findsWidgets);

      // Tap Tab 2: Profile
      await tester.tap(find.text('PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('Batuhan'), findsOneWidget);
      expect(find.text('@batuhan'), findsOneWidget);
      expect(find.text('MATCH RECORD'), findsOneWidget);
    });
  });
}
