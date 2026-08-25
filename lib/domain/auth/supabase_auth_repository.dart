import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../profile/player_profile.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_user.dart';

final class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  AppAuthState _state = const AuthBootstrapping();
  final _controller = StreamController<AppAuthState>.broadcast();
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseAuthRepository({
    required SupabaseClient client,
  }) : _client = client {
    _init();
  }

  void _init() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        try {
          final profile = await _fetchProfile(session.user.id);
          if (profile != null) {
            _state = AuthAuthenticated(
              user: AuthUser(id: session.user.id, email: session.user.email ?? ''),
              profile: profile,
            );
          } else {
            _state = const AuthUnauthenticated();
          }
        } catch (_) {
          _state = const AuthUnauthenticated();
        }
      } else {
        _state = const AuthUnauthenticated();
      }
      _controller.add(_state);
    });
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
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw StateError('Failed to retrieve user session');
      }

      final profile = await _fetchProfile(user.id);
      if (profile == null) {
        throw StateError('Profile not found for user');
      }

      _state = AuthAuthenticated(
        user: AuthUser(id: user.id, email: user.email ?? ''),
        profile: profile,
      );
      _controller.add(_state);
      return profile;
    } on AuthException catch (e) {
      final message = _translateAuthError(e.message);
      _state = AuthUnauthenticated(errorMessage: message);
      _controller.add(_state);
      throw ArgumentError(message);
    } catch (e) {
      const message = 'Unable to connect to the authentication server. Please check your connection.';
      _state = const AuthUnauthenticated(errorMessage: message);
      _controller.add(_state);
      throw StateError(message);
    }
  }

  @override
  Future<PlayerProfile> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username.trim(),
          'display_name': displayName.trim(),
        },
      );

      final user = res.user;
      if (user == null) {
        throw StateError('Failed to create account');
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        profile = await _fetchProfile(user.id);
      }

      profile ??= PlayerProfile(
        id: user.id,
        username: username,
        displayName: displayName,
        mmr: 1000,
      );

      _state = AuthAuthenticated(
        user: AuthUser(id: user.id, email: user.email ?? ''),
        profile: profile,
      );
      _controller.add(_state);
      return profile;
    } on AuthException catch (e) {
      final message = _translateAuthError(e.message);
      _state = AuthUnauthenticated(errorMessage: message);
      _controller.add(_state);
      throw ArgumentError(message);
    } catch (e) {
      const message = 'Failed to register account. Please try again.';
      _state = const AuthUnauthenticated(errorMessage: message);
      _controller.add(_state);
      throw StateError(message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    _state = const AuthUnauthenticated();
    _controller.add(_state);
  }

  @override
  Future<PlayerProfile?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _state = const AuthUnauthenticated();
      _controller.add(_state);
      return null;
    }

    try {
      final profile = await _fetchProfile(user.id);
      if (profile != null) {
        _state = AuthAuthenticated(
          user: AuthUser(id: user.id, email: user.email ?? ''),
          profile: profile,
        );
        _controller.add(_state);
        return profile;
      }
    } catch (_) {}

    _state = const AuthUnauthenticated();
    _controller.add(_state);
    return null;
  }

  @override
  Future<PlayerProfile?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  @override
  Future<PlayerProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated');
    }

    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['display_name'] = displayName.trim();
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    if (updateData.isNotEmpty) {
      await _client.from('profiles').update(updateData).eq('id', user.id);
    }

    final updated = await _fetchProfile(user.id);
    if (updated != null && _state is AuthAuthenticated) {
      _state = AuthAuthenticated(
        user: (_state as AuthAuthenticated).user,
        profile: updated,
      );
      _controller.add(_state);
      return updated;
    }
    throw StateError('Failed to refresh profile');
  }

  Future<PlayerProfile?> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return PlayerProfile.fromJson(data);
  }

  String _translateAuthError(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid grant') ||
        lower.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('user already registered') || lower.contains('already exists')) {
      return 'An account with this email or username already exists.';
    }
    if (lower.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }
    return rawMessage;
  }

  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}
