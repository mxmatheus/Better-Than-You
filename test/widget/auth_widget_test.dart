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
    testWidgets(
      'LoginScreen renders header, Google button, divider, inputs, and login button',
      (tester) async {
        final repo = LocalAuthRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: LoginScreen(authRepository: repo),
          ),
        );

        expect(find.text('BETTER\nTHAN YOU'), findsOneWidget);
        expect(find.text('PROVE IT.'), findsOneWidget);
        expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
        expect(find.text('OR'), findsOneWidget);
        expect(find.text('EMAIL'), findsOneWidget);
        expect(find.text('PASSWORD'), findsOneWidget);
        expect(find.text('ENTER ARENA'), findsOneWidget);
        expect(find.text('REGISTER'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen Google button triggers signInWithGoogle and navigates to home',
      (tester) async {
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

        await tester.tap(find.text('CONTINUE WITH GOOGLE'));
        await tester.pumpAndSettle();

        expect(repo.currentState.isAuthenticated, isTrue);
        expect(find.text('HOME_SCREEN'), findsOneWidget);
      },
    );

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

    testWidgets('LoginScreen submits valid credentials and signs in', (
      tester,
    ) async {
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

      await tester.enterText(
        find.byType(TextFormField).first,
        'player@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('ENTER ARENA'));
      await tester.pumpAndSettle();

      expect(repo.currentState.isAuthenticated, isTrue);
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });

    testWidgets(
      'RegisterScreen renders registration fields, Google button, and validates short username',
      (tester) async {
        final repo = LocalAuthRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: RegisterScreen(authRepository: repo),
          ),
        );

        expect(find.text('CLAIM IDENTITY'), findsOneWidget);
        expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
        expect(find.text('OR'), findsOneWidget);

        // Enter short username
        await tester.enterText(find.byType(TextFormField).at(0), 'ab');
        await tester.ensureVisible(find.text('CONFIRM & REGISTER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRM & REGISTER'));
        await tester.pumpAndSettle();

        expect(find.text('Username must be 3-20 characters'), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterScreen displays specific error banner when username is already taken',
      (tester) async {
        final repo = LocalAuthRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: RegisterScreen(authRepository: repo),
          ),
        );

        // Fill in valid form with taken username
        await tester.enterText(find.byType(TextFormField).at(0), 'taken_user');
        await tester.enterText(find.byType(TextFormField).at(1), 'Taken User');
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'unique_email@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.enterText(find.byType(TextFormField).at(4), 'password123');

        await tester.ensureVisible(find.text('CONFIRM & REGISTER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRM & REGISTER'));
        await tester.pumpAndSettle();

        expect(find.text('Username is already taken.'), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterScreen displays specific error banner when email is already registered',
      (tester) async {
        final repo = LocalAuthRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: RegisterScreen(authRepository: repo),
          ),
        );

        // Fill in valid form with registered email
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'new_unique_user',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'New User');
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'registered@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.enterText(find.byType(TextFormField).at(4), 'password123');

        await tester.ensureVisible(find.text('CONFIRM & REGISTER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRM & REGISTER'));
        await tester.pumpAndSettle();

        expect(find.text('Email is already registered.'), findsOneWidget);
      },
    );

    testWidgets('BootstrapScreen redirects to /login when unauthenticated', (
      tester,
    ) async {
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

    testWidgets('BootstrapScreen redirects to /home when authenticated', (
      tester,
    ) async {
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

    testWidgets(
      'AppRouter handles OAuth callback deep-link route seamlessly without error',
      (tester) async {
        final repo = LocalAuthRepository(
          initialState: const AuthAuthenticated(
            user: AuthUser(id: 'user_oauth', email: 'oauth@example.com'),
            profile: PlayerProfile(
              id: 'user_oauth',
              username: 'OAuthUser',
              displayName: 'OAuth User',
              mmr: 1000,
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            initialRoute: '/login-callback',
            onGenerateRoute: (settings) =>
                AppRouter.generateRoute(settings, authRepository: repo),
            routes: {
              AppRoutes.home: (_) => const Scaffold(body: Text('HOME_SCREEN')),
            },
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Route not found'), findsNothing);
        expect(find.text('HOME_SCREEN'), findsOneWidget);
      },
    );
  });
}
