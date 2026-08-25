import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/logging/auth_logger.dart';
import 'package:better_than_you/domain/auth/auth_controller.dart';
import 'package:better_than_you/domain/auth/auth_error.dart';
import 'package:better_than_you/domain/auth/auth_state.dart';
import 'package:better_than_you/domain/auth/local_auth_repository.dart';

void main() {
  group('AuthLogger Diagnostics & Security', () {
    test('maskEmail properly masks characters without exposing identity', () {
      expect(
        AuthLogger.maskEmail('batuhan@example.com'),
        equals('b*****n@example.com'),
      );
      expect(AuthLogger.maskEmail('alex@gmail.com'), equals('a**x@gmail.com'));
      expect(AuthLogger.maskEmail('ab@domain.com'), equals('a*@domain.com'));
      expect(AuthLogger.maskEmail('invalid-email'), equals('***'));
    });

    test(
      'AuthLogger diagnostics do not throw and accept structured params',
      () {
        expect(
          () => AuthLogger.registerStart(
            email: 'user@test.com',
            username: 'Tester',
          ),
          returnsNormally,
        );
        expect(
          () => AuthLogger.registerFailure(
            errorType: 'AuthException',
            statusCode: 400,
            code: 'user_already_exists',
            message: 'User already registered',
            mappedError: 'EmailAlreadyRegisteredError',
          ),
          returnsNormally,
        );
        expect(
          () => AuthLogger.googleStart(
            redirectTo: 'io.supabase.betterthanyou://login-callback',
          ),
          returnsNormally,
        );
        expect(
          () => AuthLogger.googleFailure(
            errorType: 'OAuthFailedError',
            message: 'OAuth window cancelled',
            mappedError: 'OAuthCancelledError',
          ),
          returnsNormally,
        );
      },
    );
  });

  group('Auth Domain — LocalAuthRepository & State Lifecycle', () {
    test('Initial state defaults to AuthUnauthenticated', () {
      final repo = LocalAuthRepository();
      expect(repo.currentState, isA<AuthUnauthenticated>());
      expect(repo.currentState.isAuthenticated, isFalse);
    });

    test(
      'Case A: Sign in with valid credentials transitions to AuthAuthenticated',
      () async {
        final repo = LocalAuthRepository();
        final profile = await repo.signIn(
          email: 'challenger@example.com',
          password: 'password123',
        );

        expect(profile.username, equals('challenger'));
        expect(repo.currentState, isA<AuthAuthenticated>());
        expect(repo.currentState.isAuthenticated, isTrue);

        final authState = repo.currentState as AuthAuthenticated;
        expect(authState.user.email, equals('challenger@example.com'));
        expect(authState.profile.mmr, equals(1000));
      },
    );

    test(
      'Case D & Invalid: Sign in with empty/short credentials throws InvalidCredentialsError',
      () async {
        final repo = LocalAuthRepository();
        expect(
          () => repo.signIn(email: '', password: ''),
          throwsA(isA<InvalidCredentialsError>()),
        );
        expect(
          () => repo.signIn(email: 'test@example.com', password: '123'),
          throwsA(isA<InvalidCredentialsError>()),
        );
      },
    );

    test(
      'Case A: Sign up with new email and username creates profile successfully',
      () async {
        final repo = LocalAuthRepository();
        final profile = await repo.signUp(
          email: 'apex@example.com',
          password: 'password123',
          username: 'ApexPlayer',
          displayName: 'Apex Player',
        );

        expect(profile.username, equals('ApexPlayer'));
        expect(profile.displayName, equals('Apex Player'));
        expect(repo.currentState.isAuthenticated, isTrue);
      },
    );

    test(
      'Case C: Sign up throws UsernameAlreadyTakenError for existing username',
      () async {
        final repo = LocalAuthRepository();
        expect(
          () => repo.signUp(
            email: 'newuser@example.com',
            password: 'password123',
            username: 'taken_user',
            displayName: 'Taken User',
          ),
          throwsA(isA<UsernameAlreadyTakenError>()),
        );
      },
    );

    test(
      'Case B: Sign up throws EmailAlreadyRegisteredError for existing email',
      () async {
        final repo = LocalAuthRepository();
        expect(
          () => repo.signUp(
            email: 'registered@example.com',
            password: 'password123',
            username: 'UniqueUser',
            displayName: 'Unique User',
          ),
          throwsA(isA<EmailAlreadyRegisteredError>()),
        );
      },
    );

    test(
      'Case E: Sign up throws WeakPasswordError for password < 6 chars',
      () async {
        final repo = LocalAuthRepository();
        expect(
          () => repo.signUp(
            email: 'newuser@example.com',
            password: '123',
            username: 'UniqueUser',
            displayName: 'Unique User',
          ),
          throwsA(isA<WeakPasswordError>()),
        );
      },
    );

    test(
      'Case A: Sign in with Google establishes authenticated session',
      () async {
        final repo = LocalAuthRepository();
        final profile = await repo.signInWithGoogle();

        expect(profile.username, equals('GoogleChampion'));
        expect(repo.currentState.isAuthenticated, isTrue);
      },
    );

    test('checkUsernameAvailable returns false for taken usernames', () async {
      final repo = LocalAuthRepository();
      expect(await repo.checkUsernameAvailable('taken_user'), isFalse);
      expect(await repo.checkUsernameAvailable('brand_new_user_123'), isTrue);
    });

    test('Sign out transitions back to AuthUnauthenticated', () async {
      final repo = LocalAuthRepository();
      await repo.signIn(email: 'test@example.com', password: 'password123');
      expect(repo.currentState.isAuthenticated, isTrue);

      await repo.signOut();
      expect(repo.currentState, isA<AuthUnauthenticated>());
      expect(repo.currentState.isAuthenticated, isFalse);
    });

    test(
      'Update profile modifies display name without altering competitive fields',
      () async {
        final repo = LocalAuthRepository();
        await repo.signIn(email: 'test@example.com', password: 'password123');

        final updated = await repo.updateProfile(
          displayName: 'Grandmaster Apex',
        );
        expect(updated.displayName, equals('Grandmaster Apex'));
        expect(updated.mmr, equals(1000));
      },
    );
  });

  group('AuthController Lifecycle', () {
    test(
      'AuthController reflects repository state changes and Google OAuth',
      () async {
        final repo = LocalAuthRepository();
        final controller = AuthController(repository: repo);

        expect(controller.isAuthenticated, isFalse);
        expect(controller.profile, isNull);

        await controller.signInWithGoogle();
        expect(controller.isAuthenticated, isTrue);
        expect(controller.profile?.username, equals('GoogleChampion'));

        await controller.signOut();
        expect(controller.isAuthenticated, isFalse);
        expect(controller.profile, isNull);
      },
    );
  });
}
