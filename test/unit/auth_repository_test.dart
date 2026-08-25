import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/auth/auth_controller.dart';
import 'package:better_than_you/domain/auth/auth_state.dart';
import 'package:better_than_you/domain/auth/local_auth_repository.dart';

void main() {
  group('Auth Domain — LocalAuthRepository & State Lifecycle', () {
    test('Initial state defaults to AuthUnauthenticated', () {
      final repo = LocalAuthRepository();
      expect(repo.currentState, isA<AuthUnauthenticated>());
      expect(repo.currentState.isAuthenticated, isFalse);
    });

    test('Sign in with valid credentials transitions to AuthAuthenticated', () async {
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
    });

    test('Sign in with invalid credentials throws ArgumentError', () async {
      final repo = LocalAuthRepository();
      expect(
        () => repo.signIn(email: '', password: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.signIn(email: 'test@example.com', password: '123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Sign up creates profile with provided username and displayName', () async {
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
    });

    test('Sign up validates username length constraints', () async {
      final repo = LocalAuthRepository();
      expect(
        () => repo.signUp(
          email: 'test@example.com',
          password: 'password123',
          username: 'ab', // < 3
          displayName: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Sign out transitions back to AuthUnauthenticated', () async {
      final repo = LocalAuthRepository();
      await repo.signIn(email: 'test@example.com', password: 'password123');
      expect(repo.currentState.isAuthenticated, isTrue);

      await repo.signOut();
      expect(repo.currentState, isA<AuthUnauthenticated>());
      expect(repo.currentState.isAuthenticated, isFalse);
    });

    test('Update profile modifies display name without altering competitive fields', () async {
      final repo = LocalAuthRepository();
      await repo.signIn(email: 'test@example.com', password: 'password123');

      final updated = await repo.updateProfile(displayName: 'Grandmaster Apex');
      expect(updated.displayName, equals('Grandmaster Apex'));
      expect(updated.mmr, equals(1000));
    });
  });

  group('AuthController Lifecycle', () {
    test('AuthController reflects repository state changes', () async {
      final repo = LocalAuthRepository();
      final controller = AuthController(repository: repo);

      expect(controller.isAuthenticated, isFalse);
      expect(controller.profile, isNull);

      await controller.signIn(email: 'hero@example.com', password: 'password123');
      expect(controller.isAuthenticated, isTrue);
      expect(controller.profile?.username, equals('hero'));

      await controller.signOut();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.profile, isNull);
    });
  });
}
