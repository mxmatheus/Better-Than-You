import '../profile/player_profile.dart';
import 'auth_state.dart';

abstract interface class AuthRepository {
  Future<PlayerProfile> signIn({
    required String email,
    required String password,
  });

  Future<PlayerProfile> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });

  Future<void> signOut();

  Future<PlayerProfile?> restoreSession();

  Future<PlayerProfile?> getProfile();

  Future<PlayerProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  Stream<AppAuthState> get authStateChanges;

  AppAuthState get currentState;
}
