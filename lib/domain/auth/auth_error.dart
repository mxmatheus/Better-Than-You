sealed class AuthError implements Exception {
  final String message;
  const AuthError(this.message);

  @override
  String toString() => message;
}

final class InvalidCredentialsError extends AuthError {
  const InvalidCredentialsError([
    super.message = 'Invalid email or password. Please try again.',
  ]);
}

final class EmailAlreadyRegisteredError extends AuthError {
  const EmailAlreadyRegisteredError([
    super.message = 'Email is already registered.',
  ]);
}

final class UsernameAlreadyTakenError extends AuthError {
  const UsernameAlreadyTakenError([
    super.message = 'Username is already taken.',
  ]);
}

final class InvalidEmailError extends AuthError {
  const InvalidEmailError([
    super.message = 'Please enter a valid email address.',
  ]);
}

final class WeakPasswordError extends AuthError {
  const WeakPasswordError([
    super.message = 'Password must be at least 6 characters long.',
  ]);
}

final class NetworkAuthError extends AuthError {
  const NetworkAuthError([
    super.message = 'Unable to connect. Please check your internet connection.',
  ]);
}

final class ProfileProvisioningError extends AuthError {
  const ProfileProvisioningError([
    super.message = "We couldn't set up your profile. Please try again.",
  ]);
}

final class OAuthCancelledError extends AuthError {
  const OAuthCancelledError([super.message = 'Google sign-in was cancelled.']);
}

final class OAuthFailedError extends AuthError {
  const OAuthFailedError([
    super.message = 'Google sign-in failed. Please try again.',
  ]);
}

final class UnknownAuthError extends AuthError {
  const UnknownAuthError([
    super.message = "We couldn't complete your request. Please try again.",
  ]);
}
