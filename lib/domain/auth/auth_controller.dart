import 'dart:async';
import 'package:flutter/foundation.dart';
import '../profile/player_profile.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  StreamSubscription<AppAuthState>? _subscription;

  AuthController({required AuthRepository repository})
    : _repository = repository {
    _subscription = _repository.authStateChanges.listen((newState) {
      notifyListeners();
    });
  }

  AppAuthState get state => _repository.currentState;

  bool get isAuthenticated => state.isAuthenticated;
  bool get isBootstrapping => state.isBootstrapping;

  PlayerProfile? get profile {
    final s = state;
    if (s is AuthAuthenticated) {
      return s.profile;
    }
    return null;
  }

  Future<void> bootstrap() async {
    await _repository.restoreSession();
    notifyListeners();
  }

  Future<PlayerProfile> signIn({
    required String email,
    required String password,
  }) async {
    final profile = await _repository.signIn(email: email, password: password);
    notifyListeners();
    return profile;
  }

  Future<PlayerProfile> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final profile = await _repository.signUp(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
    notifyListeners();
    return profile;
  }

  Future<PlayerProfile> signInWithGoogle() async {
    final profile = await _repository.signInWithGoogle();
    notifyListeners();
    return profile;
  }

  Future<bool> checkUsernameAvailable(String username) async {
    return _repository.checkUsernameAvailable(username);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    notifyListeners();
  }

  Future<PlayerProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final profile = await _repository.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
    return profile;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
