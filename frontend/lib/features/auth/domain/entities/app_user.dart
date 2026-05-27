/// Usuario autenticado usado por la app.
class AppUser {
  final String id;
  final String? email;
  final String? fullName;
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  bool get isOwner => role == 'owner' || role == 'admin';
  bool get isAdmin => role == 'admin';
}
