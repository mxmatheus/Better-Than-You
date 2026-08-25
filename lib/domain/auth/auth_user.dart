final class AuthUser {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
