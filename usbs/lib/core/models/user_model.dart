enum UserRole { superadmin, admin, client, guest }

class AppUser {
  final String uid;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.role,
  });
}
