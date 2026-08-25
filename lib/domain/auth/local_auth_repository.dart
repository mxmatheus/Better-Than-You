import 'dart:async';
import '../profile/player_profile.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_user.dart';

final class LocalAuthRepository implements AuthRepository {
  AppAuthState _state = const AuthUnauthenticated();
  final _controller = StreamController<AppAuthState>.broadcast();

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
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password cannot be empty');
    }
    if (password.length < 6) {
      throw ArgumentError('Invalid credentials');
    }

    final user = AuthUser(id: 'local_user_001', email: email);
    final profile = PlayerProfile(
      id: user.id,
      username: email.split('@').first,
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
    if (username.length < 3 || username.length > 20) {
      throw ArgumentError('Username must be between 3 and 20 characters');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }

    final user = AuthUser(id: 'local_user_${DateTime.now().millisecondsSinceEpoch}', email: email);
    final profile = PlayerProfile(
      id: user.id,
      username: username,
      displayName: displayName,
      mmr: 1000,
    );

    _state = AuthAuthenticated(user: user, profile: profile);
    _controller.add(_state);
    return profile;
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

    _state = AuthAuthenticated(
      user: current.user,
      profile: updatedProfile,
    );
    _controller.add(_state);
    return updatedProfile;
  }

  void dispose() {
    _controller.close();
  }
}
