import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthUser, AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../core/logging/auth_logger.dart';
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
      AuthLogger.authStateChanged(
        event: data.event.name,
        userId: session?.user.id,
      );

      if (session != null) {
        try {
          var profile = await _fetchProfile(session.user.id);
          if (profile == null) {
            await Future.delayed(const Duration(milliseconds: 400));
            profile = await _fetchProfile(session.user.id);
          }
          if (profile == null) {
            await Future.delayed(const Duration(milliseconds: 600));
            profile = await _fetchProfile(session.user.id);
          }

          profile ??= PlayerProfile(
            id: session.user.id,
            username:
                session.user.userMetadata?['username'] as String? ??
                session.user.userMetadata?['name'] as String? ??
                (session.user.email?.split('@').first ?? 'Challenger'),
            displayName:
                session.user.userMetadata?['display_name'] as String? ??
                session.user.userMetadata?['full_name'] as String? ??
                session.user.userMetadata?['name'] as String? ??
                'Challenger',
            avatarUrl: session.user.userMetadata?['avatar_url'] as String?,
            mmr: 1000,
          );

          _state = AuthAuthenticated(
            user: AuthUser(
              id: session.user.id,
              email: session.user.email ?? '',
            ),
            profile: profile,
          );
          AuthLogger.sessionRestored(
            userId: session.user.id,
            username: profile.username,
          );
        } catch (e) {
          _state = const AuthUnauthenticated();
          AuthLogger.sessionNotFound();
        }
      } else {
        _state = const AuthUnauthenticated();
        AuthLogger.sessionNotFound();
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
    final trimmedEmail = email.trim();
    AuthLogger.loginStart(email: trimmedEmail);

    try {
      final res = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        const error = InvalidCredentialsError();
        AuthLogger.loginFailure(
          errorType: 'NullUserResponse',
          message: 'No user returned in auth response',
          mappedError: 'InvalidCredentialsError',
        );
        throw error;
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        profile = await _fetchProfile(user.id);
      }

      if (profile == null) {
        const error = ProfileProvisioningError();
        AuthLogger.loginFailure(
          errorType: 'ProfileNotFound',
          message: 'Profile could not be fetched for user ${user.id}',
          mappedError: 'ProfileProvisioningError',
        );
        throw error;
      }

      _state = AuthAuthenticated(
        user: AuthUser(id: user.id, email: user.email ?? ''),
        profile: profile,
      );
      _controller.add(_state);
      AuthLogger.loginSuccess(userId: user.id, username: profile.username);
      return profile;
    } on supa.AuthException catch (e) {
      final error = _mapAuthException(e);
      AuthLogger.loginFailure(
        errorType: 'AuthException',
        statusCode: int.tryParse(e.statusCode ?? ''),
        code: e.code,
        message: e.message,
        mappedError: error.runtimeType.toString(),
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } on SocketException catch (e) {
      const error = NetworkAuthError();
      AuthLogger.loginFailure(
        errorType: 'SocketException',
        message: e.message,
        mappedError: 'NetworkAuthError',
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } catch (e) {
      if (e is AuthError) rethrow;
      final error = UnknownAuthError(
        'Unable to sign in. Please check your details.',
      );
      AuthLogger.loginFailure(
        errorType: e.runtimeType.toString(),
        message: e.toString(),
        mappedError: 'UnknownAuthError',
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
    final trimmedEmail = email.trim();
    final trimmedUsername = username.trim();
    final trimmedDisplayName = displayName.trim();

    AuthLogger.registerStart(email: trimmedEmail, username: trimmedUsername);

    try {
      final res = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {'username': trimmedUsername, 'display_name': trimmedDisplayName},
      );

      final user = res.user;
      if (user == null) {
        const error = UnknownAuthError(
          "We couldn't create your account. Please try again.",
        );
        AuthLogger.registerFailure(
          errorType: 'NullUserResponse',
          message: 'No user returned from signUp',
          mappedError: 'UnknownAuthError',
        );
        throw error;
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        profile = await _fetchProfile(user.id);
      }

      profile ??= PlayerProfile(
        id: user.id,
        username: trimmedUsername,
        displayName: trimmedDisplayName,
        mmr: 1000,
      );

      _state = AuthAuthenticated(
        user: AuthUser(id: user.id, email: user.email ?? ''),
        profile: profile,
      );
      _controller.add(_state);
      AuthLogger.registerSuccess(userId: user.id, username: profile.username);
      return profile;
    } on supa.AuthException catch (e) {
      final error = _mapAuthException(e);
      AuthLogger.registerFailure(
        errorType: 'AuthException',
        statusCode: int.tryParse(e.statusCode ?? ''),
        code: e.code,
        message: e.message,
        mappedError: error.runtimeType.toString(),
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } on SocketException catch (e) {
      const error = NetworkAuthError();
      AuthLogger.registerFailure(
        errorType: 'SocketException',
        message: e.message,
        mappedError: 'NetworkAuthError',
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    } catch (e) {
      if (e is AuthError) rethrow;
      final error = UnknownAuthError(
        "We couldn't create your account. Please try again.",
      );
      AuthLogger.registerFailure(
        errorType: e.runtimeType.toString(),
        message: e.toString(),
        mappedError: 'UnknownAuthError',
      );
      _state = AuthUnauthenticated(errorMessage: error.message);
      _controller.add(_state);
      throw error;
    }
  }

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    const redirectUrl = 'io.supabase.betterthanyou://login-callback';
    AuthLogger.googleStart(redirectTo: redirectUrl);

    try {
      final isLaunched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );

      if (!isLaunched) {
        const error = OAuthFailedError(
          'Could not launch Google authentication window.',
        );
        AuthLogger.googleFailure(
          errorType: 'LaunchFailure',
          message: 'signInWithOAuth returned false',
          mappedError: 'OAuthFailedError',
        );
        throw error;
      }

      AuthLogger.googleLaunched();

      final current = _client.auth.currentUser;
      if (current != null) {
        var profile = await _fetchProfile(current.id);
        if (profile == null) {
          await Future.delayed(const Duration(milliseconds: 300));
          profile = await _fetchProfile(current.id);
        }

        if (profile != null) {
          _state = AuthAuthenticated(
            user: AuthUser(id: current.id, email: current.email ?? ''),
            profile: profile,
          );
          _controller.add(_state);
          AuthLogger.googleSuccess(
            userId: current.id,
            username: profile.username,
          );
          return profile;
        }
      }

      const error = OAuthCancelledError();
      AuthLogger.googleFailure(
        errorType: 'OAuthPendingOrCancelled',
        message:
            'No immediate session after launch (waiting for deep link callback)',
        mappedError: 'OAuthCancelledError',
      );
      throw error;
    } on supa.AuthException catch (e) {
      final error = _mapAuthException(e);
      AuthLogger.googleFailure(
        errorType: 'AuthException',
        statusCode: int.tryParse(e.statusCode ?? ''),
        code: e.code,
        message: e.message,
        mappedError: error.runtimeType.toString(),
      );
      throw error;
    } catch (e) {
      if (e is AuthError) rethrow;
      const error = OAuthFailedError();
      AuthLogger.googleFailure(
        errorType: e.runtimeType.toString(),
        message: e.toString(),
        mappedError: 'OAuthFailedError',
      );
      throw error;
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
    AuthLogger.signOut();
    try {
      await _client.auth.signOut();
    } catch (_) {}
    _state = const AuthUnauthenticated();
    _controller.add(_state);
  }

  @override
  Future<PlayerProfile?> restoreSession() async {
    AuthLogger.sessionRestoreStart();
    final user = _client.auth.currentUser;
    if (user == null) {
      AuthLogger.sessionNotFound();
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
        AuthLogger.sessionRestored(userId: user.id, username: profile.username);
        return profile;
      }
    } catch (_) {}

    AuthLogger.sessionNotFound();
    _state = const AuthUnauthenticated();
    _controller.add(_state);
    return null;
  }

  @override
  Future<PlayerProfile?> getProfile() async {
    if (_state is AuthAuthenticated) {
      final cached = (_state as AuthAuthenticated).profile;
      final user = _client.auth.currentUser;
      if (user != null) {
        try {
          final fresh = await _fetchProfile(user.id);
          if (fresh != null) {
            _state = AuthAuthenticated(
              user: (_state as AuthAuthenticated).user,
              profile: fresh,
            );
            _controller.add(_state);
            return fresh;
          }
        } catch (_) {}
      }
      return cached;
    }

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
        code == 'email_exists' ||
        message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('email already exists') ||
        message.contains('email is already registered')) {
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
    if (message.contains('invalid email') ||
        message.contains('unable to validate email') ||
        code == 'invalid_email' ||
        code == 'validation_failed') {
      return const InvalidEmailError();
    }
    if (message.contains('canceled') || message.contains('cancelled')) {
      return const OAuthCancelledError();
    }
    if (message.contains('provider is not enabled') ||
        message.contains('provider_disabled') ||
        code == 'provider_disabled' ||
        message.contains('unsupported provider')) {
      return const OAuthFailedError(
        'Google sign-in is currently not enabled on this server.',
      );
    }
    if (message.contains('database error saving new user')) {
      return const UsernameAlreadyTakenError('Username is already in use.');
    }
    return UnknownAuthError(e.message);
  }

  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}
