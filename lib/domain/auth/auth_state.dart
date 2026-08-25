import '../profile/player_profile.dart';
import 'auth_user.dart';

sealed class AppAuthState {
  const AppAuthState();

  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isBootstrapping => this is AuthBootstrapping;
  bool get isUnauthenticated => this is AuthUnauthenticated;
}

final class AuthBootstrapping extends AppAuthState {
  const AuthBootstrapping();
}

final class AuthUnauthenticated extends AppAuthState {
  final String? errorMessage;

  const AuthUnauthenticated({this.errorMessage});
}

final class AuthAuthenticated extends AppAuthState {
  final AuthUser user;
  final PlayerProfile profile;

  const AuthAuthenticated({
    required this.user,
    required this.profile,
  });
}
