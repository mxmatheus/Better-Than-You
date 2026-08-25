import 'dart:async';
import '../profile/player_profile.dart';
import 'auth_error.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_user.dart';

final class LocalAuthRepository implements AuthRepository {
  AppAuthState _state = const AuthUnauthenticated();
  final _controller = StreamController<AppAuthState>.broadcast();
  final Set<String> _takenUsernames = {
    'taken_user',
    'admin',
    'player_alpha',
    'player_beta',
  };
  final Set<String> _registeredEmails = {
    'registered@example.com',
    'player_alpha@betterthanyou.internal',
  };

  LocalAuthRepository({AppAuthState? initialState}) {
    if (initialState != null) {
      _state = initialState;
    }
  }

  @override
  AppAuthState get currentState => _state;

  @override
  Stream<AppAuthState> get authStateChanges => _controller.stream;

  @override
  Future<PlayerProfile> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const InvalidCredentialsError('Email and password cannot be empty');
    }
    if (password.length < 6) {
      throw const InvalidCredentialsError();
    }

    final user = AuthUser(id: 'local_user_001', email: trimmedEmail);
    final profile = PlayerProfile(
      id: user.id,
      username: trimmedEmail.split('@').first,
      displayName: 'Local Champion',
      mmr: 1000,
    );

    _state = AuthAuthenticated(user: user, profile: profile);
    _controller.add(_state);
    return profile;
  }

  @override
  Future<PlayerProfile> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final trimmedUsername = username.trim();
    final trimmedEmail = email.trim();

    if (trimmedUsername.length < 3 || trimmedUsername.length > 20) {
      throw const UnknownAuthError(
        'Username must be between 3 and 20 characters',
      );
    }
    if (password.length < 6) {
      throw const WeakPasswordError();
    }
    if (_takenUsernames.contains(trimmedUsername.toLowerCase())) {
      throw const UsernameAlreadyTakenError();
    }
    if (_registeredEmails.contains(trimmedEmail.toLowerCase())) {
      throw const EmailAlreadyRegisteredError();
    }

    final user = AuthUser(
      id: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
      email: trimmedEmail,
    );
    final profile = PlayerProfile(
      id: user.id,
      username: trimmedUsername,
      displayName: displayName.trim(),
      mmr: 1000,
    );

    _takenUsernames.add(trimmedUsername.toLowerCase());
    _registeredEmails.add(trimmedEmail.toLowerCase());

    _state = AuthAuthenticated(user: user, profile: profile);
    _controller.add(_state);
    return profile;
  }

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    final user = AuthUser(
      id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'google_player@gmail.com',
    );
    final profile = PlayerProfile(
      id: user.id,
      username: 'GoogleChampion',
      displayName: 'Google Champion',
      mmr: 1000,
    );

    _state = AuthAuthenticated(user: user, profile: profile);
    _controller.add(_state);
    return profile;
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.length < 3 || trimmed.length > 20) return false;
    return !_takenUsernames.contains(trimmed);
  }

  @override
  Future<void> signOut() async {
    _state = const AuthUnauthenticated();
    _controller.add(_state);
  }

  @override
  Future<PlayerProfile?> restoreSession() async {
    if (_state is AuthAuthenticated) {
      return (_state as AuthAuthenticated).profile;
    }
    _state = const AuthUnauthenticated();
    _controller.add(_state);
    return null;
  }

  @override
  Future<PlayerProfile?> getProfile() async {
    if (_state is AuthAuthenticated) {
      return (_state as AuthAuthenticated).profile;
    }
    return null;
  }

  @override
  Future<PlayerProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_state is! AuthAuthenticated) {
      throw StateError('User is not authenticated');
    }

    final current = (_state as AuthAuthenticated);
    final updatedProfile = current.profile.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    _state = AuthAuthenticated(user: current.user, profile: updatedProfile);
    _controller.add(_state);
    return updatedProfile;
  }

  void dispose() {
    _controller.close();
  }
}
