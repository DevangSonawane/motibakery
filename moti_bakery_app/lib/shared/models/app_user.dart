enum UserRole { counter, cakeRoom }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
  });

  final String id;
  final String email;
  final UserRole role;
  final String displayName;
}
