import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/routing/app_router.dart';
import 'package:better_than_you/core/theme/app_theme.dart';
import 'package:better_than_you/domain/auth/auth_state.dart';
import 'package:better_than_you/domain/auth/auth_user.dart';
import 'package:better_than_you/domain/auth/local_auth_repository.dart';
import 'package:better_than_you/domain/profile/player_profile.dart';
import 'package:better_than_you/presentation/auth/bootstrap_screen.dart';
import 'package:better_than_you/presentation/auth/login_screen.dart';
import 'package:better_than_you/presentation/auth/register_screen.dart';

void main() {
  group('Auth Widget Tests — LoginScreen & RegisterScreen', () {
    testWidgets('LoginScreen renders header, inputs, and login button', (tester) async {
      final repo = LocalAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LoginScreen(authRepository: repo),
        ),
      );

      expect(find.text('BETTER\nTHAN YOU'), findsOneWidget);
      expect(find.text('PROVE IT.'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('ENTER ARENA'), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);
    });

    testWidgets('LoginScreen validates empty inputs on submit', (tester) async {
      final repo = LocalAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LoginScreen(authRepository: repo),
        ),
      );

      await tester.tap(find.text('ENTER ARENA'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('LoginScreen submits valid credentials and signs in', (tester) async {
      final repo = LocalAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LoginScreen(authRepository: repo),
          routes: {
            AppRoutes.home: (_) => const Scaffold(body: Text('HOME_SCREEN')),
          },
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'player@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('ENTER ARENA'));
      await tester.pumpAndSettle();

      expect(repo.currentState.isAuthenticated, isTrue);
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders registration fields and validates short username', (tester) async {
      final repo = LocalAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: RegisterScreen(authRepository: repo),
        ),
      );

      expect(find.text('CLAIM IDENTITY'), findsOneWidget);

      // Enter short username
      await tester.enterText(find.byType(TextFormField).at(0), 'ab');
      await tester.ensureVisible(find.text('CONFIRM & REGISTER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRM & REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('Username must be 3-20 characters'), findsOneWidget);
    });

    testWidgets('BootstrapScreen redirects to /login when unauthenticated', (tester) async {
      final repo = LocalAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BootstrapScreen(authRepository: repo),
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('LOGIN_SCREEN')),
            AppRoutes.home: (_) => const Scaffold(body: Text('HOME_SCREEN')),
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    });

    testWidgets('BootstrapScreen redirects to /home when authenticated', (tester) async {
      final repo = LocalAuthRepository(
        initialState: const AuthAuthenticated(
          user: AuthUser(id: 'user_1', email: 'test@example.com'),
          profile: PlayerProfile(id: 'user_1', username: 'Champion', mmr: 1000),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BootstrapScreen(authRepository: repo),
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('LOGIN_SCREEN')),
            AppRoutes.home: (_) => const Scaffold(body: Text('HOME_SCREEN')),
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });
  });
}
