import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthUser, AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../profile/player_profile.dart';
import 'auth_error.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_user.dart';

final class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  AppAuthState _state = const AuthBootstrapping();
  final _controller = StreamController<AppAuthState>.broadcast();
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseAuthRepository({required SupabaseClient client}) : _client = client {
    _init();
  }

  void _init() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        try {
          var profile = await _fetchProfile(session.user.id);
          if (profile == null) {
            // Profile trigger may be asynchronous on first OAuth login
            await Future.delayed(const Duration(milliseconds: 300));
            profile = await _fetchProfile(session.user.id);
          }

          if (profile != null) {
            _state = AuthAuthenticated(
              user: AuthUser(
                id: session.user.id,
                email: session.user.email ?? '',
              ),
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
        throw const InvalidCredentialsError();
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        profile = await _fetchProfile(user.id);
      }

      if (profile == null) {
        throw const ProfileProvisioningError();
      }

      _state = AuthAuthenticated(
        user: AuthUser(id: user.id, email: user.email ?? ''),
        profile: profile,
      );
      _controller.add(_state);
      return profile;
    } on supa.AuthException catch (e) {
      final error = _mapAuthException(e);
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } on SocketException {
      const error = NetworkAuthError();
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } catch (e) {
      if (e is AuthError) rethrow;
      const error = UnknownAuthError(
        'Unable to sign in. Please check your details.',
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
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
        data: {'username': username.trim(), 'display_name': displayName.trim()},
      );

      final user = res.user;
      if (user == null) {
        throw const UnknownAuthError(
          "We couldn't create your account. Please try again.",
        );
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        profile = await _fetchProfile(user.id);
      }

      profile ??= PlayerProfile(
        id: user.id,
        username: username.trim(),
        displayName: displayName.trim(),
        mmr: 1000,
      );

      _state = AuthAuthenticated(
        user: AuthUser(id: user.id, email: user.email ?? ''),
        profile: profile,
      );
      _controller.add(_state);
      return profile;
    } on supa.AuthException catch (e) {
      final error = _mapAuthException(e);
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } on SocketException {
      const error = NetworkAuthError();
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } catch (e) {
      if (e is AuthError) rethrow;
      const error = UnknownAuthError(
        "We couldn't create your account. Please try again.",
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    }
  }

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    try {
      final isLaunched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.betterthanyou://login-callback',
      );

      if (!isLaunched) {
        throw const OAuthFailedError(
          'Could not launch Google authentication window.',
        );
      }

      final current = _client.auth.currentUser;
      if (current != null) {
        final profile = await _fetchProfile(current.id);
        if (profile != null) {
          _state = AuthAuthenticated(
            user: AuthUser(id: current.id, email: current.email ?? ''),
            profile: profile,
          );
          _controller.add(_state);
          return profile;
        }
      }

      throw const OAuthCancelledError();
    } on supa.AuthException catch (e) {
      final error = _mapAuthException(e);
      throw error;
    } catch (e) {
      if (e is AuthError) rethrow;
      throw const OAuthFailedError();
    }
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    final trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 20) return false;

    try {
      final res = await _client.rpc(
        'check_username_available',
        params: {'p_username': trimmed},
      );
      return res as bool? ?? false;
    } catch (_) {
      return false;
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
      throw const InvalidCredentialsError('User is not authenticated');
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
    throw const ProfileProvisioningError('Failed to refresh profile');
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

  AuthError _mapAuthException(supa.AuthException e) {
    final message = e.message.toLowerCase();
    final code = e.code?.toLowerCase() ?? '';

    if (message.contains('username_already_taken') ||
        message.contains('profiles_username_key') ||
        message.contains('username is already taken')) {
      return const UsernameAlreadyTakenError();
    }
    if (code == 'user_already_exists' ||
        message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('email already exists')) {
      return const EmailAlreadyRegisteredError();
    }
    if (code == 'invalid_credentials' ||
        code == 'invalid_grant' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return const InvalidCredentialsError();
    }
    if (message.contains('password should be at least') ||
        message.contains('weak password') ||
        code == 'weak_password') {
      return const WeakPasswordError();
    }
    if (message.contains('invalid email') || code == 'invalid_email') {
      return const InvalidEmailError();
    }
    if (message.contains('canceled') || message.contains('cancelled')) {
      return const OAuthCancelledError();
    }
    if (message.contains('database error saving new user')) {
      return const UsernameAlreadyTakenError(
        'Username or email is already in use.',
      );
    }
    return UnknownAuthError(e.message);
  }

  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}
